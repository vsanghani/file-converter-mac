import SwiftUI
import UniformTypeIdentifiers

/// Drag-and-drop zone for adding files
struct DropZoneView: View {
    @ObservedObject var viewModel: ConverterViewModel
    @State private var isTargeted = false
    @State private var showFileImporter = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isTargeted
                        ? Color.accentColor.opacity(0.15)
                        : Color(nsColor: .controlBackgroundColor).opacity(0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isTargeted)

            // Content
            VStack(spacing: 16) {
                Image(systemName: isTargeted ? "arrow.down.circle.fill" : "square.and.arrow.down")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        isTargeted
                            ? AnyShapeStyle(Color.accentColor)
                            : AnyShapeStyle(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .scaleEffect(isTargeted ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: isTargeted)

                VStack(spacing: 6) {
                    Text("Drop Files Here")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("or click to browse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Button(action: { showFileImporter = true }) {
                    Label("Browse Files", systemImage: "folder")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                // Supported formats hint
                Text("Images • Documents • Audio • Video")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(32)
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: SupportedFormat.allUTTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                let accessibleURLs = urls.compactMap { url -> URL? in
                    guard url.startAccessingSecurityScopedResource() else { return nil }
                    return url
                }
                viewModel.addFiles(urls: accessibleURLs)
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
            }
        }
        .onTapGesture {
            showFileImporter = true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in
                    viewModel.addFiles(urls: [url])
                }
            }
        }
    }
}

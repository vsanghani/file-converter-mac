import SwiftUI
import UniformTypeIdentifiers

/// Glassmorphic drag-and-drop zone
struct DropZoneView: View {
    @ObservedObject var viewModel: ConverterViewModel
    @State private var isTargeted = false
    @State private var showFileImporter = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            isTargeted
                                ? Color.cyan.opacity(0.1)
                                : Color.white.opacity(0.04)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            isTargeted
                                ? LinearGradient(
                                    colors: [.cyan.opacity(0.6), .blue.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [.white.opacity(0.15), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            style: StrokeStyle(
                                lineWidth: isTargeted ? 2 : 1,
                                dash: isTargeted ? [] : [12, 8]
                            )
                        )
                )
                .shadow(color: isTargeted ? .cyan.opacity(0.2) : .black.opacity(0.1), radius: 20, y: 8)
                .animation(.easeInOut(duration: 0.3), value: isTargeted)

            // Content
            VStack(spacing: 20) {
                // Animated icon
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3), .cyan.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.6)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.15),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )

                    Image(systemName: isTargeted ? "arrow.down.circle.fill" : "square.and.arrow.down.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isTargeted ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3), value: isTargeted)
                }

                VStack(spacing: 6) {
                    Text(isTargeted ? "Release to Add" : "Drop Files Here")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("or browse from your Mac")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }

                // Browse button
                Button(action: { showFileImporter = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14))
                        Text("Browse Files")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                    .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)

                // Supported formats
                HStack(spacing: 16) {
                    formatHint(icon: "photo.fill", text: "Images", color: .blue)
                    formatHint(icon: "doc.text.fill", text: "Documents", color: .orange)
                    formatHint(icon: "film.fill", text: "Media", color: .purple)
                }
            }
            .padding(36)
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
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }
        }
    }

    private func formatHint(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color.opacity(0.8))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
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

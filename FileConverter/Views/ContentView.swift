import SwiftUI

/// Main content view of the File Converter application
struct ContentView: View {
    @StateObject private var viewModel = ConverterViewModel()

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 0) {
                // Title bar area
                titleBar

                // Main content
                ScrollView {
                    VStack(spacing: 16) {
                        // Drop zone
                        DropZoneView(viewModel: viewModel)
                            .frame(minHeight: viewModel.hasFiles ? 140 : 200)

                        // Format picker (shown when files are added)
                        if viewModel.hasFiles {
                            FormatPickerView(viewModel: viewModel)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Progress (shown during/after conversion)
                        if viewModel.isConverting || viewModel.overallProgress > 0 {
                            ConversionProgressView(viewModel: viewModel)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Output directory selector
                        if viewModel.hasFiles {
                            outputDirectorySection
                                .transition(.opacity)
                        }

                        // Convert button
                        if viewModel.hasFiles {
                            convertButton
                                .transition(.scale.combined(with: .opacity))
                        }

                        // File list
                        if viewModel.hasFiles {
                            FileListView(viewModel: viewModel)
                                .frame(minHeight: 150)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasFiles)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isConverting)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 550)
        .alert("Conversion Complete", isPresented: $viewModel.showCompletionAlert) {
            Button("OK") {}
        } message: {
            Text(completionMessage)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .windowBackgroundColor).opacity(0.95),
                Color.accentColor.opacity(0.03)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("File Converter")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Convert images, documents & media locally")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Supported formats count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(SupportedFormat.allCases.count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("formats supported")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var outputDirectorySection: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundColor(.secondary)

            if let dir = viewModel.outputDirectory {
                Text(dir.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.head)
            } else {
                Text("Save to: Same as source folder")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Change...") {
                viewModel.chooseOutputDirectory()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }

    private var convertButton: some View {
        Button(action: {
            if viewModel.isConverting {
                viewModel.cancelConversion()
            } else {
                viewModel.startConversion()
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isConverting ? "stop.fill" : "bolt.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text(viewModel.isConverting ? "Cancel" : "Convert Files")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        viewModel.isConverting
                            ? AnyShapeStyle(Color.red.opacity(0.8))
                            : AnyShapeStyle(LinearGradient(
                                colors: viewModel.canConvert
                                    ? [.blue, .purple]
                                    : [.gray.opacity(0.5), .gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
            )
            .foregroundColor(.white)
            .shadow(color: viewModel.canConvert ? .blue.opacity(0.3) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canConvert && !viewModel.isConverting)
    }

    private var completionMessage: String {
        if viewModel.failedCount > 0 {
            return "\(viewModel.completedCount) file(s) converted successfully, \(viewModel.failedCount) failed."
        }
        return "\(viewModel.completedCount) file(s) converted successfully!"
    }
}

import SwiftUI

/// Main content view — immersive glassmorphism layout
struct ContentView: View {
    @ObservedObject var viewModel: ConverterViewModel
    @State private var showPrivacyOnboarding = false
    @State private var showHowConversionsWork = false

    var body: some View {
        ZStack {
            // Animated background
            AnimatedMeshBackground()

            // Main layout
            VStack(spacing: 0) {
                // Custom title bar
                customTitleBar
                    .padding(.top, 8)

                PrivacyTrustBanner {
                    showHowConversionsWork = true
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                // Content area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Drop zone
                        DropZoneView(viewModel: viewModel)
                            .frame(minHeight: viewModel.hasFiles ? 160 : 220)

                        // Format picker + controls
                        if viewModel.hasFiles {
                            FormatPickerView(viewModel: viewModel)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }

                        // Progress
                        if viewModel.isConverting || viewModel.overallProgress > 0 {
                            ConversionProgressView(viewModel: viewModel)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Action buttons
                        if viewModel.hasFiles {
                            actionButtons
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                        }

                        // File list
                        if viewModel.hasFiles {
                            FileListView(viewModel: viewModel)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.hasFiles)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isConverting)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !PrivacyOnboardingState.hasSeen {
                showPrivacyOnboarding = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showHowConversionsWork)) { _ in
            showHowConversionsWork = true
        }
        .sheet(isPresented: $showPrivacyOnboarding, onDismiss: {
            PrivacyOnboardingState.hasSeen = true
        }) {
            PrivacyOnboardingView(isPresented: $showPrivacyOnboarding) {
                showHowConversionsWork = true
            }
        }
        .sheet(isPresented: $showHowConversionsWork) {
            HowConversionsWorkView()
        }
        .alert("Conversion Complete", isPresented: $viewModel.showCompletionAlert) {
            Button("OK") {}
            if viewModel.completedCount > 0 {
                Button("Open in Finder") {
                    if let job = viewModel.jobs.first(where: { $0.status.isCompleted }) {
                        viewModel.revealInFinder(job)
                    }
                }
            }
        } message: {
            Text(completionMessage)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Custom Title Bar

    private var customTitleBar: some View {
        HStack(spacing: 16) {
            // App icon area
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("File Converter")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Convert anything, locally")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Stats pill
            HStack(spacing: 8) {
                statPill(
                    icon: "doc.on.doc.fill",
                    value: "\(viewModel.jobs.count)",
                    label: "files"
                )

                statPill(
                    icon: "square.grid.3x3.fill",
                    value: "\(SupportedFormat.allCases.count)",
                    label: "formats"
                )
            }

            // Output folder button
            Button(action: viewModel.chooseOutputDirectory) {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                    Text(viewModel.outputDirectory?.lastPathComponent ?? "Source folder")
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.cyan.opacity(0.8))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if viewModel.isConverting {
                GlowButton(
                    title: "Cancel",
                    icon: "stop.fill",
                    colors: [.red.opacity(0.8), .orange.opacity(0.7)]
                ) {
                    viewModel.cancelConversion()
                }
            } else {
                GlowButton(
                    title: "Convert \(viewModel.jobs.count) File\(viewModel.jobs.count == 1 ? "" : "s")",
                    icon: "bolt.fill",
                    colors: [
                        Color(red: 0.3, green: 0.5, blue: 1.0),
                        Color(red: 0.6, green: 0.3, blue: 1.0)
                    ],
                    isDisabled: !viewModel.canConvert
                ) {
                    viewModel.startConversion()
                }
            }
        }
    }

    private var completionMessage: String {
        if viewModel.failedCount > 0 {
            return "\(viewModel.completedCount) file(s) converted successfully, \(viewModel.failedCount) failed."
        }
        return "\(viewModel.completedCount) file(s) converted successfully!"
    }
}

// MARK: - Privacy trust line (main screen)

private struct PrivacyTrustBanner: View {
    let onLearnMore: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green.opacity(0.85))
            Text("Your files never leave this Mac — processed only on your device.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
            Spacer(minLength: 0)
            Button("How conversions work") {
                onLearnMore()
            }
            .font(.system(size: 12, weight: .semibold))
            .buttonStyle(.plain)
            .foregroundColor(.cyan.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

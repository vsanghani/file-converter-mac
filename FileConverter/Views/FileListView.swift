import SwiftUI

/// Glassmorphic file list
struct FileListView: View {
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 14))

                    Text("\(viewModel.jobs.count) file\(viewModel.jobs.count == 1 ? "" : "s") queued")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if !viewModel.jobs.isEmpty {
                    Button(action: viewModel.clearAll) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Clear")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                        .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isConverting)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            // Subtle separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // File rows
            if viewModel.jobs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No files added")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.jobs) { job in
                            GlassFileRow(job: job, viewModel: viewModel)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 6)
                }
            }
        }
        .frame(minHeight: 180)
        .glassCard(cornerRadius: 20)
    }
}

// MARK: - Glass File Row

struct GlassFileRow: View {
    @ObservedObject var job: ConversionJob
    let viewModel: ConverterViewModel
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // File type icon with glow
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: fileIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }

            // File info
            VStack(alignment: .leading, spacing: 3) {
                Text(job.fileName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Text(job.formattedFileSize)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))

                    HStack(spacing: 4) {
                        GlassFormatTag(job.sourceFormat.displayName, color: .cyan)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white.opacity(0.2))
                        GlassFormatTag(job.targetFormat.displayName, color: .green)
                    }
                }
            }

            Spacer()

            // Status indicator
            statusView

            // Remove button
            if !viewModel.isConverting {
                Button(action: { viewModel.removeJob(job) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(isHovered ? 0.4 : 0.15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color.white.opacity(0.04) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            if job.status.isCompleted, job.outputURL != nil {
                Button {
                    viewModel.revealInFinder(job)
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
            }
            Button(role: .destructive) {
                viewModel.removeJob(job)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch job.status {
        case .pending:
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.2))
        case .converting(let progress):
            GlassCircularProgress(progress: progress)
                .frame(width: 26, height: 26)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(.red)
        }
    }

    private var fileIcon: String {
        switch job.sourceFormat.category {
        case .image: return "photo.fill"
        case .document: return "doc.text.fill"
        case .media: return "film.fill"
        }
    }

    private var iconColor: Color {
        switch job.sourceFormat.category {
        case .image: return .cyan
        case .document: return .orange
        case .media: return .purple
        }
    }
}

// MARK: - Glass Circular Progress

struct GlassCircularProgress: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 3)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)

            // Glow at tip
            if progress > 0 && progress < 1 {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 4, height: 4)
                    .blur(radius: 2)
                    .offset(y: -11)
                    .rotationEffect(.degrees(360 * progress - 90))
            }
        }
    }
}

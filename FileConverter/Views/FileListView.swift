import SwiftUI

/// List of files queued or converted
struct FileListView: View {
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Label("\(viewModel.jobs.count) file\(viewModel.jobs.count == 1 ? "" : "s")",
                      systemImage: "doc.on.doc")
                    .font(.headline)

                Spacer()

                if !viewModel.jobs.isEmpty {
                    Button(action: viewModel.clearAll) {
                        Label("Clear All", systemImage: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isConverting)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().opacity(0.3)

            // File list
            if viewModel.jobs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No files added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.jobs) { job in
                            FileRowView(job: job, viewModel: viewModel)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - File Row

struct FileRowView: View {
    @ObservedObject var job: ConversionJob
    let viewModel: ConverterViewModel
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            Image(systemName: fileIcon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 36)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(job.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 6) {
                    Text(job.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Format badges
                    HStack(spacing: 4) {
                        FormatBadge(text: job.sourceFormat.displayName, color: .blue)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        FormatBadge(text: job.targetFormat.displayName, color: .green)
                    }
                }
            }

            Spacer()

            // Status
            statusView

            // Actions
            if !viewModel.isConverting {
                Button(action: { viewModel.removeJob(job) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(isHovered ? 0.8 : 0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            if job.status.isCompleted, job.outputURL != nil {
                Button("Reveal in Finder") { viewModel.revealInFinder(job) }
            }
            Button("Remove") { viewModel.removeJob(job) }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch job.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundColor(.secondary)
        case .converting(let progress):
            CircularProgressView(progress: progress)
                .frame(width: 24, height: 24)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 18))
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
        case .image: return .blue
        case .document: return .orange
        case .media: return .purple
        }
    }
}

// MARK: - Format Badge

struct FormatBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
            .foregroundColor(color)
    }
}

// MARK: - Circular Progress

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: progress)
        }
    }
}

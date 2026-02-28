import SwiftUI

/// Progress indicator for active conversions
struct ConversionProgressView: View {
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(viewModel.isConverting ? 360 : 0))
                    .animation(
                        viewModel.isConverting
                            ? .linear(duration: 2).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isConverting
                    )

                Text(viewModel.isConverting ? "Converting..." : "Ready")
                    .font(.headline)

                Spacer()

                if viewModel.isConverting {
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.overallProgress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.overallProgress)
                }
            }
            .frame(height: 8)

            // Stats
            HStack(spacing: 16) {
                if viewModel.completedCount > 0 {
                    Label("\(viewModel.completedCount) completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                if viewModel.failedCount > 0 {
                    Label("\(viewModel.failedCount) failed", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

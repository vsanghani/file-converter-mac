import SwiftUI

/// Glassmorphic progress view
struct ConversionProgressView: View {
    @ObservedObject var viewModel: ConverterViewModel
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(viewModel.isConverting ? 360 : 0))
                        .animation(
                            viewModel.isConverting
                                ? .linear(duration: 2).repeatForever(autoreverses: false)
                                : .default,
                            value: viewModel.isConverting
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isConverting ? "Converting..." : "Conversion Complete")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(statusDetail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                // Percentage
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Progress bar with shimmer
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 10)

                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.8, blue: 1.0),
                                    Color(red: 0.4, green: 0.4, blue: 1.0),
                                    Color(red: 0.7, green: 0.3, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * viewModel.overallProgress), height: 10)
                        .overlay(
                            // Shimmer effect
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .white.opacity(0.3),
                                            .clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset)
                                .mask(
                                    RoundedRectangle(cornerRadius: 6)
                                )
                        )
                        .animation(.easeInOut(duration: 0.4), value: viewModel.overallProgress)

                    // Glow at the edge
                    if viewModel.overallProgress > 0 && viewModel.overallProgress < 1 {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 10, height: 10)
                            .blur(radius: 6)
                            .offset(x: geometry.size.width * viewModel.overallProgress - 5)
                    }
                }
            }
            .frame(height: 10)

            // Stats row
            HStack(spacing: 16) {
                if viewModel.completedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text("\(viewModel.completedCount) completed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                if viewModel.failedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        Text("\(viewModel.failedCount) failed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                Spacer()
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }

    private var statusDetail: String {
        if viewModel.isConverting {
            return "\(viewModel.completedCount) of \(viewModel.jobs.count) files processed"
        }
        return "\(viewModel.completedCount) file(s) successfully converted"
    }
}

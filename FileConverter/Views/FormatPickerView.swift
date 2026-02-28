import SwiftUI

/// Glassmorphic format picker
struct FormatPickerView: View {
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .font(.system(size: 16))

                    Text("Convert To")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if let category = viewModel.detectedCategory {
                    HStack(spacing: 5) {
                        Image(systemName: category.systemImage)
                            .font(.system(size: 10))
                        Text(category.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(categoryColor(category).opacity(0.15))
                            .overlay(
                                Capsule()
                                    .strokeBorder(categoryColor(category).opacity(0.3), lineWidth: 0.5)
                            )
                    )
                    .foregroundColor(categoryColor(category))
                }
            }

            if viewModel.availableOutputFormats.isEmpty {
                Text("Add files to see available formats")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                // Format grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 86, maximum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(viewModel.availableOutputFormats) { format in
                        GlassFormatButton(
                            format: format,
                            isSelected: viewModel.selectedOutputFormat == format
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.updateOutputFormat(format)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
    }

    private func categoryColor(_ category: FileCategory) -> Color {
        switch category {
        case .image: return .cyan
        case .document: return .orange
        case .media: return .purple
        }
    }
}

// MARK: - Glass Format Button

struct GlassFormatButton: View {
    let format: SupportedFormat
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: formatIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            : AnyShapeStyle(Color.white.opacity(0.6))
                    )

                Text(format.displayName)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected
                                ? Color.blue.opacity(0.2)
                                : (isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
                        )
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.5), .blue.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
                }
            )
            .shadow(color: isSelected ? .blue.opacity(0.15) : .clear, radius: 8, y: 2)
            .scaleEffect(isSelected ? 1.03 : (isHovered ? 1.01 : 1.0))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
        .animation(.spring(response: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var formatIcon: String {
        switch format.category {
        case .image: return "photo"
        case .document: return "doc.text"
        case .media: return "waveform"
        }
    }
}

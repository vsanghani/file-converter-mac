import SwiftUI

/// Picker for selecting the output format
struct FormatPickerView: View {
    @ObservedObject var viewModel: ConverterViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Label("Convert To", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if let category = viewModel.detectedCategory {
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(categoryColor(category).opacity(0.15))
                        )
                        .foregroundColor(categoryColor(category))
                }
            }

            if viewModel.availableOutputFormats.isEmpty {
                Text("Add files to see available formats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                // Format grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(viewModel.availableOutputFormats) { format in
                        FormatButton(
                            format: format,
                            isSelected: viewModel.selectedOutputFormat == format
                        ) {
                            viewModel.updateOutputFormat(format)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }

    private func categoryColor(_ category: FileCategory) -> Color {
        switch category {
        case .image: return .blue
        case .document: return .orange
        case .media: return .purple
        }
    }
}

// MARK: - Format Button

struct FormatButton: View {
    let format: SupportedFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: formatIcon)
                    .font(.system(size: 18))

                Text(format.displayName)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.2), value: isSelected)
    }

    private var formatIcon: String {
        switch format.category {
        case .image: return "photo"
        case .document: return "doc.text"
        case .media: return "waveform"
        }
    }
}

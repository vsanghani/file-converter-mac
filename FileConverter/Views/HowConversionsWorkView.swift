import SwiftUI

/// Technical transparency: Apple frameworks and system tools used for local conversion.
struct HowConversionsWorkView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("How conversions work")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    section(
                        title: "Privacy",
                        icon: "lock.shield.fill",
                        tint: .green
                    ) {
                        Text("All conversion runs on your Mac. This app does not send your files or filenames to our servers — there are no servers involved in processing.")
                        bullet("No account or sign-in.")
                        bullet("No analytics or tracking enabled by default.")
                        Text("If optional crash reporting is ever added, it would be off by default and clearly labeled in settings.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    section(
                        title: "Images",
                        icon: "photo.fill",
                        tint: .blue
                    ) {
                        Text("Raster and vector image conversion uses Apple’s on-device frameworks:")
                        frameworkRow("Core Image", "Filters and image processing.")
                        frameworkRow("ImageIO", "Reading and writing PNG, JPEG, HEIC, WebP, TIFF, and other bitmap formats.")
                        frameworkRow("AppKit", "NSImage and color management where needed.")
                        frameworkRow("PDFKit", "Creating PDFs from images and rendering PDF pages to images.")
                    }

                    section(
                        title: "Documents",
                        icon: "doc.text.fill",
                        tint: .orange
                    ) {
                        Text("PDF and rich text workflows use:")
                        frameworkRow("PDFKit", "PDF rendering, text extraction, and PDF export.")
                        frameworkRow("AppKit", "Attributed strings and document formats such as RTF.")
                        Text("Microsoft Word (.docx) conversion uses Apple’s textutil command-line tool (included with macOS) to convert between Word, RTF, HTML, and plain text on your machine.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    section(
                        title: "Media",
                        icon: "film.fill",
                        tint: .purple
                    ) {
                        frameworkRow("AVFoundation", "Reading and writing audio and video — transcoding, export, and track handling.")
                    }

                    section(
                        title: "Other",
                        icon: "cpu",
                        tint: .cyan
                    ) {
                        Text("General file handling uses Foundation for file I/O and coordination. Everything above runs locally through system frameworks and tools Apple ships with macOS.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .padding(20)
                .padding(.bottom, 12)
            }
        }
        .frame(minWidth: 440, idealWidth: 480, maxWidth: 560, minHeight: 420, idealHeight: 520, maxHeight: 640)
        .background(
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.14)
                LinearGradient(
                    colors: [Color.white.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }

    private func section<Content: View>(title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint.opacity(0.9))
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func frameworkRow(_ name: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan.opacity(0.95))
            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.white.opacity(0.5))
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
    }
}

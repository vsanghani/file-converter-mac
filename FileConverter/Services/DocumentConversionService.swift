import Foundation
import AppKit
import PDFKit
import UniformTypeIdentifiers

/// Service for converting between document formats
actor DocumentConversionService {

    /// Convert a document file from one format to another
    func convert(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL) async throws {
        guard let sourceFormat = SupportedFormat.detect(from: sourceURL),
              sourceFormat.category == .document else {
            throw ConversionError.unsupportedFormat(sourceURL.pathExtension)
        }

        // PDF source — special handling
        if sourceFormat == .pdf {
            try convertFromPDF(sourceURL: sourceURL, targetFormat: targetFormat, outputURL: outputURL)
            return
        }

        // Non-PDF source — load as NSAttributedString
        let attributedString = try loadAttributedString(from: sourceURL, format: sourceFormat)

        // Convert to target
        switch targetFormat {
        case .pdf:
            try createPDFFromAttributedString(attributedString, outputURL: outputURL)
        case .rtf:
            try writeAttributedString(attributedString, to: outputURL, documentType: .rtf)
        case .rtfd:
            try writeAttributedString(attributedString, to: outputURL, documentType: .rtfd)
        case .txt:
            try attributedString.string.write(to: outputURL, atomically: true, encoding: .utf8)
        case .html:
            try writeAttributedString(attributedString, to: outputURL, documentType: .html)
        default:
            throw ConversionError.incompatibleFormats(sourceFormat.displayName, targetFormat.displayName)
        }
    }

    // MARK: - Private Helpers

    private func loadAttributedString(from url: URL, format: SupportedFormat) throws -> NSAttributedString {
        let data = try Data(contentsOf: url)

        let documentType: NSAttributedString.DocumentType
        switch format {
        case .rtf: documentType = .rtf
        case .rtfd: documentType = .rtfd
        case .html: documentType = .html
        case .txt: documentType = .plain
        default:
            throw ConversionError.unsupportedFormat(format.displayName)
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: documentType,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return try NSAttributedString(data: data, options: options, documentAttributes: nil)
    }

    private func writeAttributedString(_ attrString: NSAttributedString, to url: URL, documentType: NSAttributedString.DocumentType) throws {
        let range = NSRange(location: 0, length: attrString.length)

        if documentType == .rtfd {
            // RTFD is a file wrapper (directory)
            guard let wrapper = attrString.rtfdFileWrapper(from: range, documentAttributes: [:]) else {
                throw ConversionError.failedToWrite(url.lastPathComponent)
            }
            try wrapper.write(to: url, options: .atomic, originalContentsURL: nil)
        } else {
            let data = try attrString.data(
                from: range,
                documentAttributes: [.documentType: documentType]
            )
            try data.write(to: url, options: .atomic)
        }
    }

    private func convertFromPDF(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL) throws {
        guard let pdfDocument = PDFDocument(url: sourceURL) else {
            throw ConversionError.failedToLoadFile(sourceURL.lastPathComponent)
        }

        switch targetFormat {
        case .txt:
            // Extract text from all pages
            guard let text = pdfDocument.string else {
                throw ConversionError.failedToProcess("Could not extract text from PDF")
            }
            try text.write(to: outputURL, atomically: true, encoding: .utf8)

        case .rtf:
            // Extract text and create basic RTF
            guard let text = pdfDocument.string else {
                throw ConversionError.failedToProcess("Could not extract text from PDF")
            }
            let attrString = NSAttributedString(
                string: text,
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.textColor
                ]
            )
            try writeAttributedString(attrString, to: outputURL, documentType: .rtf)

        case .html:
            guard let text = pdfDocument.string else {
                throw ConversionError.failedToProcess("Could not extract text from PDF")
            }
            let paragraphs = text.components(separatedBy: "\n")
                .map { "<p>\(escapeHTML($0))</p>" }
                .joined(separator: "\n")
            let html = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"><title>Converted Document</title></head>
            <body>
            \(paragraphs)
            </body>
            </html>
            """
            try html.write(to: outputURL, atomically: true, encoding: .utf8)

        default:
            throw ConversionError.incompatibleFormats("PDF", targetFormat.displayName)
        }
    }

    private func createPDFFromAttributedString(_ attrString: NSAttributedString, outputURL: URL) throws {
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let margin: CGFloat = 72 // 1 inch margins
        let textRect = CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - 2 * margin,
            height: pageSize.height - 2 * margin
        )

        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ConversionError.failedToProcess("Could not create PDF context")
        }

        // Create framesetter for multi-page text layout
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        var currentIndex = 0
        let totalLength = attrString.length

        while currentIndex < totalLength {
            pdfContext.beginPage(mediaBox: &mediaBox)

            // Flip coordinate system for text
            pdfContext.textMatrix = .identity
            pdfContext.translateBy(x: 0, y: pageSize.height)
            pdfContext.scaleBy(x: 1.0, y: -1.0)

            let framePath = CGPath(rect: textRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRangeMake(currentIndex, 0),
                framePath,
                nil
            )

            CTFrameDraw(frame, pdfContext)

            let visibleRange = CTFrameGetVisibleStringRange(frame)
            currentIndex += max(visibleRange.length, 1)

            pdfContext.endPage()
        }

        pdfContext.closePDF()
        try pdfData.write(to: outputURL, options: .atomic)
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

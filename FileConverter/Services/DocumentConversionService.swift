import Foundation
import AppKit
import PDFKit
import UniformTypeIdentifiers

/// Service for converting between document formats
struct DocumentConversionService {

    /// Convert a document file from one format to another
    func convert(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL) throws {
        guard let sourceFormat = SupportedFormat.detect(from: sourceURL),
              sourceFormat.category == .document else {
            throw ConversionError.unsupportedFormat(sourceURL.pathExtension)
        }

        // Read data into memory first (handles security-scoped resources)
        let sourceData = try Data(contentsOf: sourceURL)

        guard !sourceData.isEmpty else {
            throw ConversionError.failedToLoadFile(sourceURL.lastPathComponent)
        }

        // PDF source — special handling
        if sourceFormat == .pdf {
            try convertFromPDF(data: sourceData, targetFormat: targetFormat, outputURL: outputURL)
            return
        }

        // DOCX source — use textutil CLI
        if sourceFormat == .docx {
            try convertFromDOCX(sourceURL: sourceURL, targetFormat: targetFormat, outputURL: outputURL)
            return
        }

        // CSV source — plain text conversion
        if sourceFormat == .csv {
            try convertFromCSV(data: sourceData, targetFormat: targetFormat, outputURL: outputURL)
            return
        }

        // Markdown source
        if sourceFormat == .md {
            try convertFromMarkdown(data: sourceData, targetFormat: targetFormat, outputURL: outputURL)
            return
        }

        // Non-PDF source — load as NSAttributedString
        let attributedString = try loadAttributedString(from: sourceData, format: sourceFormat)

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
        case .md:
            try convertToMarkdown(attributedString, outputURL: outputURL)
        case .csv:
            try attributedString.string.write(to: outputURL, atomically: true, encoding: .utf8)
        default:
            throw ConversionError.incompatibleFormats(sourceFormat.displayName, targetFormat.displayName)
        }
    }

    // MARK: - Private Helpers

    private func loadAttributedString(from data: Data, format: SupportedFormat) throws -> NSAttributedString {
        let documentType: NSAttributedString.DocumentType
        switch format {
        case .rtf: documentType = .rtf
        case .rtfd: documentType = .rtfd
        case .html: documentType = .html
        case .txt: documentType = .plain
        default:
            throw ConversionError.unsupportedFormat(format.displayName)
        }

        // Try without specifying encoding first, then with UTF-8
        var options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: documentType
        ]

        if format == .txt {
            options[.characterEncoding] = String.Encoding.utf8.rawValue
        }

        do {
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            // Fallback: try as plain text
            if let text = String(data: data, encoding: .utf8) {
                return NSAttributedString(
                    string: text,
                    attributes: [
                        .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                        .foregroundColor: NSColor.black
                    ]
                )
            }
            throw ConversionError.failedToLoadFile("Could not read document: \(error.localizedDescription)")
        }
    }

    private func writeAttributedString(_ attrString: NSAttributedString, to url: URL, documentType: NSAttributedString.DocumentType) throws {
        let range = NSRange(location: 0, length: attrString.length)

        if documentType == .rtfd {
            guard let wrapper = attrString.rtfdFileWrapper(from: range, documentAttributes: [:]) else {
                throw ConversionError.failedToWrite(url.lastPathComponent)
            }
            try wrapper.write(to: url, options: .atomic, originalContentsURL: nil)
        } else {
            let data = try attrString.data(
                from: range,
                documentAttributes: [.documentType: documentType]
            )
            guard !data.isEmpty else {
                throw ConversionError.failedToWrite("Converted data is empty")
            }
            try data.write(to: url, options: .atomic)
        }
    }

    private func convertFromPDF(data: Data, targetFormat: SupportedFormat, outputURL: URL) throws {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw ConversionError.failedToLoadFile("Could not parse PDF data")
        }

        guard pdfDocument.pageCount > 0 else {
            throw ConversionError.failedToProcess("PDF has no pages")
        }

        switch targetFormat {
        case .txt:
            let text = pdfDocument.string ?? ""
            guard !text.isEmpty else {
                throw ConversionError.failedToProcess("No text content found in PDF")
            }
            try text.write(to: outputURL, atomically: true, encoding: .utf8)

        case .rtf:
            let text = pdfDocument.string ?? ""
            guard !text.isEmpty else {
                throw ConversionError.failedToProcess("No text content found in PDF")
            }
            let attrString = NSAttributedString(
                string: text,
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.black
                ]
            )
            try writeAttributedString(attrString, to: outputURL, documentType: .rtf)

        case .html:
            let text = pdfDocument.string ?? ""
            guard !text.isEmpty else {
                throw ConversionError.failedToProcess("No text content found in PDF")
            }
            let paragraphs = text.components(separatedBy: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { "<p>\(escapeHTML($0))</p>" }
                .joined(separator: "\n")
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <title>Converted Document</title>
                <style>body { font-family: -apple-system, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; }</style>
            </head>
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

        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        var currentIndex = 0
        let totalLength = attrString.length

        while currentIndex < totalLength {
            pdfContext.beginPage(mediaBox: &mediaBox)
            pdfContext.textMatrix = .identity
            pdfContext.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))

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

        guard pdfData.length > 0 else {
            throw ConversionError.failedToWrite("Generated PDF data is empty")
        }

        try pdfData.write(to: outputURL, options: .atomic)
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    // MARK: - DOCX Conversion (via textutil)

    private func convertFromDOCX(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL) throws {
        let textutilFormat: String
        switch targetFormat {
        case .txt:  textutilFormat = "txt"
        case .html: textutilFormat = "html"
        case .rtf:  textutilFormat = "rtf"
        case .pdf:
            // textutil → html → then we render to PDF
            let tmpHTML = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".html")
            try runTextutil(sourceURL: sourceURL, format: "html", outputURL: tmpHTML)
            let htmlData = try Data(contentsOf: tmpHTML)
            let attrString = try loadAttributedString(from: htmlData, format: .html)
            try createPDFFromAttributedString(attrString, outputURL: outputURL)
            try? FileManager.default.removeItem(at: tmpHTML)
            return
        default:
            throw ConversionError.incompatibleFormats("DOCX", targetFormat.displayName)
        }
        try runTextutil(sourceURL: sourceURL, format: textutilFormat, outputURL: outputURL)
    }

    private func runTextutil(sourceURL: URL, format: String, outputURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        // textutil writes to the same dir with changed extension; we'll redirect with -output
        process.arguments = [
            "-convert", format,
            "-output", outputURL.path,
            sourceURL.path
        ]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw ConversionError.failedToProcess("textutil failed: \(errMsg)")
        }

        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ConversionError.failedToWrite("textutil did not produce output at \(outputURL.lastPathComponent)")
        }
    }

    // MARK: - CSV Conversion

    private func convertFromCSV(data: Data, targetFormat: SupportedFormat, outputURL: URL) throws {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ConversionError.failedToLoadFile("Could not decode CSV as text")
        }

        switch targetFormat {
        case .txt:
            try text.write(to: outputURL, atomically: true, encoding: .utf8)

        case .html:
            let html = csvToHTML(text)
            try html.write(to: outputURL, atomically: true, encoding: .utf8)

        case .md:
            let md = csvToMarkdown(text)
            try md.write(to: outputURL, atomically: true, encoding: .utf8)

        case .pdf:
            let html = csvToHTML(text)
            guard let htmlData = html.data(using: .utf8) else {
                throw ConversionError.failedToProcess("Could not encode CSV HTML")
            }
            let attrString = try loadAttributedString(from: htmlData, format: .html)
            try createPDFFromAttributedString(attrString, outputURL: outputURL)

        default:
            try text.write(to: outputURL, atomically: true, encoding: .utf8)
        }
    }

    private func csvToHTML(_ csv: String) -> String {
        let rows = parseCSVRows(csv)
        var tableRows = ""
        for (i, cols) in rows.enumerated() {
            let tag = i == 0 ? "th" : "td"
            let cells = cols.map { "<\(tag)>\(escapeHTML($0))</\(tag)>" }.joined()
            tableRows += "<tr>\(cells)</tr>\n"
        }
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Converted CSV</title>
            <style>
                body { font-family: -apple-system, sans-serif; padding: 20px; }
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ccc; padding: 8px 12px; text-align: left; }
                th { background: #f0f0f0; font-weight: bold; }
                tr:nth-child(even) { background: #f9f9f9; }
            </style>
        </head>
        <body>
        <table>
        \(tableRows)
        </table>
        </body>
        </html>
        """
    }

    private func csvToMarkdown(_ csv: String) -> String {
        let rows = parseCSVRows(csv)
        guard !rows.isEmpty else { return "" }
        var lines: [String] = []
        for (i, cols) in rows.enumerated() {
            lines.append("| " + cols.joined(separator: " | ") + " |")
            if i == 0 {
                lines.append("| " + cols.map { _ in "---" }.joined(separator: " | ") + " |")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func parseCSVRows(_ csv: String) -> [[String]] {
        csv.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { line in
                line.components(separatedBy: ",").map {
                    $0.trimmingCharacters(in: .init(charactersIn: " \""))
                }
            }
    }

    // MARK: - Markdown Conversion

    private func convertFromMarkdown(data: Data, targetFormat: SupportedFormat, outputURL: URL) throws {
        guard let mdText = String(data: data, encoding: .utf8) else {
            throw ConversionError.failedToLoadFile("Could not decode Markdown as UTF-8")
        }

        switch targetFormat {
        case .txt:
            // Strip Markdown syntax to plain text
            let plain = stripMarkdown(mdText)
            try plain.write(to: outputURL, atomically: true, encoding: .utf8)

        case .html:
            let html = markdownToHTML(mdText)
            try html.write(to: outputURL, atomically: true, encoding: .utf8)

        case .pdf:
            let html = markdownToHTML(mdText)
            guard let htmlData = html.data(using: .utf8) else {
                throw ConversionError.failedToProcess("Could not encode Markdown HTML")
            }
            let attrString = try loadAttributedString(from: htmlData, format: .html)
            try createPDFFromAttributedString(attrString, outputURL: outputURL)

        case .rtf:
            let html = markdownToHTML(mdText)
            guard let htmlData = html.data(using: .utf8) else {
                throw ConversionError.failedToProcess("Could not encode Markdown HTML")
            }
            let attrString = try loadAttributedString(from: htmlData, format: .html)
            try writeAttributedString(attrString, to: outputURL, documentType: .rtf)

        default:
            try mdText.write(to: outputURL, atomically: true, encoding: .utf8)
        }
    }

    private func convertToMarkdown(_ attrString: NSAttributedString, outputURL: URL) throws {
        // Best-effort plain text → Markdown (no styling info in plain text)
        try attrString.string.write(to: outputURL, atomically: true, encoding: .utf8)
    }

    /// Minimal Markdown → HTML converter covering headings, bold, italic, code, links, lists
    private func markdownToHTML(_ md: String) -> String {
        let lines = md.components(separatedBy: "\n")
        var html: [String] = []
        var inCodeBlock = false
        var inList = false

        for line in lines {
            if line.hasPrefix("```") {
                if inList { html.append("</ul>"); inList = false }
                if inCodeBlock {
                    html.append("</code></pre>")
                    inCodeBlock = false
                } else {
                    html.append("<pre><code>")
                    inCodeBlock = true
                }
                continue
            }

            if inCodeBlock {
                html.append(escapeHTML(line))
                continue
            }

            // Headings
            if line.hasPrefix("### ") {
                if inList { html.append("</ul>"); inList = false }
                html.append("<h3>\(inlineMarkdown(String(line.dropFirst(4))))</h3>")
            } else if line.hasPrefix("## ") {
                if inList { html.append("</ul>"); inList = false }
                html.append("<h2>\(inlineMarkdown(String(line.dropFirst(3))))</h2>")
            } else if line.hasPrefix("# ") {
                if inList { html.append("</ul>"); inList = false }
                html.append("<h1>\(inlineMarkdown(String(line.dropFirst(2))))</h1>")
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                if !inList { html.append("<ul>"); inList = true }
                html.append("<li>\(inlineMarkdown(String(line.dropFirst(2))))</li>")
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if inList { html.append("</ul>"); inList = false }
                html.append("")
            } else {
                if inList { html.append("</ul>"); inList = false }
                html.append("<p>\(inlineMarkdown(line))</p>")
            }
        }

        if inList { html.append("</ul>") }
        if inCodeBlock { html.append("</code></pre>") }

        let body = html.joined(separator: "\n")
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Converted Document</title>
            <style>body { font-family: -apple-system, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; } pre { background: #f4f4f4; padding: 12px; border-radius: 4px; overflow-x: auto; } code { font-family: monospace; } </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    private func inlineMarkdown(_ text: String) -> String {
        var result = escapeHTML(text)
        // Bold
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        result = result.replacingOccurrences(of: #"__(.+?)__"#, with: "<strong>$1</strong>", options: .regularExpression)
        // Italic
        result = result.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        result = result.replacingOccurrences(of: #"_(.+?)_"#, with: "<em>$1</em>", options: .regularExpression)
        // Inline code
        result = result.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)
        // Links
        result = result.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        return result
    }

    private func stripMarkdown(_ md: String) -> String {
        var result = md
        result = result.replacingOccurrences(of: #"#{1,6} "#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"`(.+?)`"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[(.+?)\]\(.+?\)"#, with: "$1", options: .regularExpression)
        if let regex = try? NSRegularExpression(pattern: #"^[-*] "#, options: .anchorsMatchLines) {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "• ")
        }
        return result
    }
}

import Foundation
import AppKit
import CoreImage
import UniformTypeIdentifiers
import ImageIO
import PDFKit

/// Service for converting between image formats using Core Image and ImageIO
struct ImageConversionService {

    /// Convert an image file from one format to another.
    /// Returns an array of output URLs (multiple for PDF multi-page exports).
    @discardableResult
    func convert(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL, jpegQuality: CGFloat = 0.9) throws -> [URL] {
        // Read file data into memory first (handles security-scoped resources)
        let sourceData = try Data(contentsOf: sourceURL)

        guard !sourceData.isEmpty else {
            throw ConversionError.failedToLoadFile(sourceURL.lastPathComponent)
        }

        // If target is PDF, use a different path
        if targetFormat == .pdf {
            try createPDFFromImageData(sourceData, outputURL: outputURL)
            return [outputURL]
        }

        // SVG wrapper (raster embedded in SVG)
        if targetFormat == .svg {
            try createSVGFromImageData(sourceData, outputURL: outputURL)
            return [outputURL]
        }

        // Use ImageIO for reliable format conversion
        guard let imageSource = CGImageSourceCreateWithData(sourceData as CFData, nil) else {
            throw ConversionError.failedToLoadFile(sourceURL.lastPathComponent)
        }

        // Get image properties
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) else {
            throw ConversionError.failedToProcess("Could not decode image from source data")
        }

        // Get the target UTType
        guard let targetUTType = targetFormat.utType else {
            throw ConversionError.unsupportedFormat(targetFormat.displayName)
        }

        // Write using CGImageDestination
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            targetUTType.identifier as CFString,
            1,
            nil
        ) else {
            throw ConversionError.failedToWrite(outputURL.lastPathComponent)
        }

        // Set options
        var destOptions: [CFString: Any] = [:]
        if targetFormat == .jpg || targetFormat == .jpeg {
            destOptions[kCGImageDestinationLossyCompressionQuality] = jpegQuality
        }

        CGImageDestinationAddImage(destination, cgImage, destOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.failedToWrite(outputURL.lastPathComponent)
        }

        // Verify output was created and is non-empty
        let attrs = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        guard let fileSize = attrs[.size] as? Int64, fileSize > 0 else {
            throw ConversionError.failedToWrite("Output file is empty")
        }
        return [outputURL]
    }

    /// Render each page of a PDF as a separate image file.
    /// Returns the array of output URLs written (one per page).
    func convertPDFToImages(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL, jpegQuality: CGFloat = 0.9) throws -> [URL] {
        let sourceData = try Data(contentsOf: sourceURL)
        guard let pdfDocument = PDFDocument(data: sourceData), pdfDocument.pageCount > 0 else {
            throw ConversionError.failedToLoadFile("Could not parse PDF: \(sourceURL.lastPathComponent)")
        }

        guard let targetUTType = targetFormat.utType else {
            throw ConversionError.unsupportedFormat(targetFormat.displayName)
        }

        let directory = outputURL.deletingLastPathComponent()
        let baseName = outputURL.deletingPathExtension().lastPathComponent
        let ext = targetFormat.fileExtension
        let scale: CGFloat = 2.0 // 2× for good resolution

        var outputURLs: [URL] = []

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }

            let pageRect = page.bounds(for: .mediaBox)
            let imageSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let bitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(imageSize.width),
                pixelsHigh: Int(imageSize.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )

            guard let rep = bitmapRep else {
                throw ConversionError.failedToProcess("Could not create bitmap for page \(pageIndex + 1)")
            }

            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            NSColor.white.setFill()
            NSRect(origin: .zero, size: imageSize).fill()
            let context = NSGraphicsContext.current?.cgContext
            context?.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context!)
            NSGraphicsContext.restoreGraphicsState()

            let pageURL: URL
            if pdfDocument.pageCount == 1 {
                pageURL = outputURL
            } else {
                let suffix = String(format: "_page%03d", pageIndex + 1)
                pageURL = directory.appendingPathComponent("\(baseName)\(suffix).\(ext)")
            }

            guard let cgImage = rep.cgImage else {
                throw ConversionError.failedToProcess("Could not get CGImage for page \(pageIndex + 1)")
            }

            guard let destination = CGImageDestinationCreateWithURL(
                pageURL as CFURL,
                targetUTType.identifier as CFString,
                1,
                nil
            ) else {
                throw ConversionError.failedToWrite(pageURL.lastPathComponent)
            }

            var destOptions: [CFString: Any] = [:]
            if targetFormat == .jpg || targetFormat == .jpeg {
                destOptions[kCGImageDestinationLossyCompressionQuality] = jpegQuality
            }

            CGImageDestinationAddImage(destination, cgImage, destOptions as CFDictionary)
            guard CGImageDestinationFinalize(destination) else {
                throw ConversionError.failedToWrite(pageURL.lastPathComponent)
            }
            outputURLs.append(pageURL)
        }

        return outputURLs
    }

    /// Create a PDF containing a single image
    private func createPDFFromImageData(_ data: Data, outputURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ConversionError.failedToProcess("Could not decode image for PDF creation")
        }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        // Scale down if image is very large (keep aspect ratio, max 2000pt)
        let maxDimension: CGFloat = 2000
        let scale = min(1.0, maxDimension / max(width, height))
        let pdfWidth = width * scale
        let pdfHeight = height * scale

        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pdfWidth, height: pdfHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ConversionError.failedToProcess("Could not create PDF context")
        }

        pdfContext.beginPage(mediaBox: &mediaBox)
        pdfContext.draw(cgImage, in: mediaBox)
        pdfContext.endPage()
        pdfContext.closePDF()

        guard pdfData.length > 0 else {
            throw ConversionError.failedToWrite("Generated PDF data is empty")
        }

        try pdfData.write(to: outputURL, options: .atomic)
    }

    /// Embed a raster image inside an SVG wrapper
    private func createSVGFromImageData(_ data: Data, outputURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ConversionError.failedToProcess("Could not decode image for SVG creation")
        }

        let width = cgImage.width
        let height = cgImage.height

        // Re-encode the source as PNG for embedding
        let pngData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(pngData as CFMutableData, UTType.png.identifier as CFString, 1, nil) else {
            throw ConversionError.failedToProcess("Could not create PNG encoder for SVG")
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.failedToProcess("Could not encode PNG for SVG")
        }

        let base64 = (pngData as Data).base64EncodedString()
        let svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="\(width)" height="\(height)" viewBox="0 0 \(width) \(height)">
          <image width="\(width)" height="\(height)" xlink:href="data:image/png;base64,\(base64)"/>
        </svg>
        """

        guard let svgData = svg.data(using: .utf8) else {
            throw ConversionError.failedToWrite("Could not encode SVG text")
        }
        try svgData.write(to: outputURL, options: .atomic)
    }
}

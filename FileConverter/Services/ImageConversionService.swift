import Foundation
import AppKit
import CoreImage
import UniformTypeIdentifiers
import ImageIO

/// Service for converting between image formats using Core Image and ImageIO
struct ImageConversionService {

    /// Convert an image file from one format to another
    func convert(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL, jpegQuality: CGFloat = 0.9) throws {
        // Read file data into memory first (handles security-scoped resources)
        let sourceData = try Data(contentsOf: sourceURL)

        guard !sourceData.isEmpty else {
            throw ConversionError.failedToLoadFile(sourceURL.lastPathComponent)
        }

        // If target is PDF, use a different path
        if targetFormat == .pdf {
            try createPDFFromImageData(sourceData, outputURL: outputURL)
            return
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
}

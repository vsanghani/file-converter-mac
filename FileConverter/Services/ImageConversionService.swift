import Foundation
import AppKit
import CoreImage
import UniformTypeIdentifiers

/// Service for converting between image formats using Core Image and ImageIO
actor ImageConversionService {

    private let ciContext = CIContext()

    /// Convert an image file from one format to another
    func convert(sourceURL: URL, targetFormat: SupportedFormat, outputURL: URL, jpegQuality: CGFloat = 0.9) async throws {
        guard let sourceFormat = SupportedFormat.detect(from: sourceURL),
              sourceFormat.category == .image || sourceFormat == .pdf else {
            throw ConversionError.unsupportedFormat(sourceURL.pathExtension)
        }

        // Load the image
        guard let nsImage = NSImage(contentsOf: sourceURL) else {
            throw ConversionError.failedToLoadFile(sourceURL.lastPathComponent)
        }

        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ConversionError.failedToProcess("Could not create CGImage from source")
        }

        // If target is PDF, use a different path
        if targetFormat == .pdf {
            try createPDFFromImage(cgImage: cgImage, size: nsImage.size, outputURL: outputURL)
            return
        }

        // Get the target UTType
        guard let targetUTType = targetFormat.utType else {
            throw ConversionError.unsupportedFormat(targetFormat.displayName)
        }

        // Create image destination
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            targetUTType.identifier as CFString,
            1,
            nil
        ) else {
            throw ConversionError.failedToWrite(outputURL.lastPathComponent)
        }

        // Set options
        var options: [CFString: Any] = [:]
        if targetFormat == .jpg || targetFormat == .jpeg {
            options[kCGImageDestinationLossyCompressionQuality] = jpegQuality
        }

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.failedToWrite(outputURL.lastPathComponent)
        }
    }

    /// Create a PDF containing a single image
    private func createPDFFromImage(cgImage: CGImage, size: NSSize, outputURL: URL) throws {
        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: size)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ConversionError.failedToProcess("Could not create PDF context")
        }

        pdfContext.beginPage(mediaBox: &mediaBox)
        pdfContext.draw(cgImage, in: mediaBox)
        pdfContext.endPage()
        pdfContext.closePDF()

        try pdfData.write(to: outputURL, options: .atomic)
    }
}

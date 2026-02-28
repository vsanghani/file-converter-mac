import Foundation

/// Coordinates conversion jobs across the appropriate service
class ConversionEngine {
    private let imageService = ImageConversionService()
    private let documentService = DocumentConversionService()
    private let mediaService = MediaConversionService()

    /// Convert a single file, returning the output URL
    func convert(
        job: ConversionJob,
        outputDirectory: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        // Build output file URL
        let baseName = job.sourceURL.deletingPathExtension().lastPathComponent
        let outputFileName = "\(baseName).\(job.targetFormat.fileExtension)"
        var outputURL = outputDirectory.appendingPathComponent(outputFileName)

        // Handle file name collisions
        outputURL = uniqueURL(for: outputURL)

        // Route to appropriate service
        switch job.sourceFormat.category {
        case .image:
            // Image source can go to image output or PDF
            if job.targetFormat == .pdf {
                try await imageService.convert(
                    sourceURL: job.sourceURL,
                    targetFormat: job.targetFormat,
                    outputURL: outputURL
                )
            } else {
                try await imageService.convert(
                    sourceURL: job.sourceURL,
                    targetFormat: job.targetFormat,
                    outputURL: outputURL
                )
            }
            progressHandler(1.0)

        case .document:
            try await documentService.convert(
                sourceURL: job.sourceURL,
                targetFormat: job.targetFormat,
                outputURL: outputURL
            )
            progressHandler(1.0)

        case .media:
            try await mediaService.convert(
                sourceURL: job.sourceURL,
                targetFormat: job.targetFormat,
                outputURL: outputURL,
                progressHandler: progressHandler
            )
        }

        return outputURL
    }

    /// Generate a unique file URL to avoid overwrites
    private func uniqueURL(for url: URL) -> URL {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { return url }

        let directory = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 1
        var candidateURL: URL
        repeat {
            candidateURL = directory.appendingPathComponent("\(baseName) (\(counter)).\(ext)")
            counter += 1
        } while fileManager.fileExists(atPath: candidateURL.path)

        return candidateURL
    }
}

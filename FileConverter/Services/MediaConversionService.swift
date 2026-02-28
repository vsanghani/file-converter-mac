import Foundation
import AVFoundation

/// Service for converting between audio/video formats using AVFoundation
actor MediaConversionService {

    /// Convert a media file from one format to another
    func convert(
        sourceURL: URL,
        targetFormat: SupportedFormat,
        outputURL: URL,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws {
        guard let sourceFormat = SupportedFormat.detect(from: sourceURL),
              sourceFormat.category == .media else {
            throw ConversionError.unsupportedFormat(sourceURL.pathExtension)
        }

        let asset = AVURLAsset(url: sourceURL)

        // Determine the export preset
        let preset = exportPreset(for: targetFormat, from: sourceFormat)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw ConversionError.failedToProcess("Could not create export session")
        }

        // Determine the output file type
        guard let outputFileType = avFileType(for: targetFormat) else {
            throw ConversionError.unsupportedFormat(targetFormat.displayName)
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType

        // Start progress monitoring
        let progressTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(nanoseconds: 250_000_000) // 250ms
                let progress = Double(exportSession.progress)
                progressHandler(progress)
            }
        }

        // Perform export
        await exportSession.export()
        progressTask.cancel()

        switch exportSession.status {
        case .completed:
            progressHandler(1.0)
        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            throw ConversionError.failedToProcess(errorMessage)
        case .cancelled:
            throw ConversionError.cancelled
        default:
            throw ConversionError.failedToProcess("Unexpected export status: \(exportSession.status.rawValue)")
        }
    }

    // MARK: - Private Helpers

    private func exportPreset(for target: SupportedFormat, from source: SupportedFormat) -> String {
        let audioFormats: [SupportedFormat] = [.m4a, .wav, .aiff]

        if audioFormats.contains(target) {
            return AVAssetExportPresetAppleM4A
        }

        return AVAssetExportPresetHighestQuality
    }

    private func avFileType(for format: SupportedFormat) -> AVFileType? {
        switch format {
        case .mov: return .mov
        case .mp4: return .mp4
        case .m4v: return .m4v
        case .m4a: return .m4a
        case .wav: return .wav
        case .aiff: return AVFileType(rawValue: "public.aiff-audio")
        default: return nil
        }
    }
}

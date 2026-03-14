import Foundation
import AVFoundation

/// Service for converting between audio/video formats using AVFoundation
struct MediaConversionService {

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

        // Verify asset has tracks
        let tracks = try await asset.loadTracks(withMediaType: .video) + (try await asset.loadTracks(withMediaType: .audio))
        guard !tracks.isEmpty else {
            throw ConversionError.failedToLoadFile("No audio or video tracks found in \(sourceURL.lastPathComponent)")
        }

        // Determine the export preset
        let preset = exportPreset(for: targetFormat, from: sourceFormat)

        // Check if preset is compatible
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let finalPreset = compatiblePresets.contains(preset) ? preset : AVAssetExportPresetPassthrough

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: finalPreset) else {
            throw ConversionError.failedToProcess("Could not create export session")
        }

        guard let outputFileType = avFileType(for: targetFormat) else {
            throw ConversionError.unsupportedFormat(targetFormat.displayName)
        }

        // Remove existing output file if present
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = outputFileType

        // Start progress monitoring
        let progressTask = Task.detached {
            while !Task.isCancelled {
                try await Task.sleep(nanoseconds: 200_000_000) // 200ms
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
            // Verify output
            guard FileManager.default.fileExists(atPath: outputURL.path) else {
                throw ConversionError.failedToWrite("Output file was not created")
            }
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
        let audioFormats: [SupportedFormat] = [.m4a, .aac, .wav, .aiff]

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
        case .aac: return .m4a  // AAC audio is exported as an M4A container
        case .wav: return .wav
        case .aiff: return AVFileType(rawValue: "public.aiff-audio")
        case .avi: return AVFileType(rawValue: "public.avi")
        default: return nil
        }
    }
}

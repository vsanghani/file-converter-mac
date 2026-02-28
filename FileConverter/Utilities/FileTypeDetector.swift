import Foundation
import UniformTypeIdentifiers

/// Utility for detecting file types and validating file compatibility
struct FileTypeDetector {

    /// Detect the SupportedFormat from a file URL
    static func detectFormat(from url: URL) -> SupportedFormat? {
        return SupportedFormat.detect(from: url)
    }

    /// Check if a file is supported for conversion
    static func isSupported(_ url: URL) -> Bool {
        return detectFormat(from: url) != nil
    }

    /// Get the UTType for a file URL
    static func utType(for url: URL) -> UTType? {
        let ext = url.pathExtension.lowercased()
        return UTType(filenameExtension: ext)
    }

    /// Filter an array of URLs to only include supported files
    static func filterSupported(_ urls: [URL]) -> [URL] {
        urls.filter { isSupported($0) }
    }

    /// Get display info for a file
    static func fileInfo(for url: URL) -> (name: String, format: SupportedFormat?, size: String) {
        let name = url.lastPathComponent
        let format = detectFormat(from: url)
        let size: String
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attrs[.size] as? Int64 {
            size = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        } else {
            size = "Unknown"
        }
        return (name, format, size)
    }
}

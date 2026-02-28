import Foundation

/// Errors that can occur during file conversion
enum ConversionError: LocalizedError {
    case unsupportedFormat(String)
    case failedToLoadFile(String)
    case failedToProcess(String)
    case failedToWrite(String)
    case incompatibleFormats(String, String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .failedToLoadFile(let name):
            return "Failed to load file: \(name)"
        case .failedToProcess(let reason):
            return "Processing error: \(reason)"
        case .failedToWrite(let name):
            return "Failed to write output: \(name)"
        case .incompatibleFormats(let source, let target):
            return "Cannot convert \(source) to \(target)"
        case .cancelled:
            return "Conversion was cancelled"
        }
    }
}

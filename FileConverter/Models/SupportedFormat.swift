import Foundation
import UniformTypeIdentifiers

// MARK: - File Category

enum FileCategory: String, CaseIterable, Identifiable {
    case image = "Images"
    case document = "Documents"
    case media = "Media"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .document: return "doc.text"
        case .media: return "film"
        }
    }
}

// MARK: - Supported Format

enum SupportedFormat: String, CaseIterable, Identifiable, Hashable {
    // Images
    case png
    case jpg
    case jpeg
    case heic
    case heif
    case bmp
    case tiff
    case gif
    case webp
    case ico

    // Documents
    case pdf
    case rtf
    case rtfd
    case txt
    case html

    // Media
    case mov
    case mp4
    case m4v
    case m4a
    case wav
    case aiff

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpg: return "JPG"
        case .jpeg: return "JPEG"
        case .heic: return "HEIC"
        case .heif: return "HEIF"
        case .bmp: return "BMP"
        case .tiff: return "TIFF"
        case .gif: return "GIF"
        case .webp: return "WebP"
        case .ico: return "ICO"
        case .pdf: return "PDF"
        case .rtf: return "RTF"
        case .rtfd: return "RTFD"
        case .txt: return "Plain Text"
        case .html: return "HTML"
        case .mov: return "MOV"
        case .mp4: return "MP4"
        case .m4v: return "M4V"
        case .m4a: return "M4A"
        case .wav: return "WAV"
        case .aiff: return "AIFF"
        }
    }

    var fileExtension: String {
        rawValue
    }

    var category: FileCategory {
        switch self {
        case .png, .jpg, .jpeg, .heic, .heif, .bmp, .tiff, .gif, .webp, .ico:
            return .image
        case .pdf, .rtf, .rtfd, .txt, .html:
            return .document
        case .mov, .mp4, .m4v, .m4a, .wav, .aiff:
            return .media
        }
    }

    var utType: UTType? {
        switch self {
        case .png: return .png
        case .jpg, .jpeg: return .jpeg
        case .heic, .heif: return .heic
        case .bmp: return .bmp
        case .tiff: return .tiff
        case .gif: return .gif
        case .webp: return .webP
        case .ico: return .ico
        case .pdf: return .pdf
        case .rtf: return .rtf
        case .rtfd: return .rtfd
        case .txt: return .plainText
        case .html: return .html
        case .mov: return .quickTimeMovie
        case .mp4: return .mpeg4Movie
        case .m4v: return .appleProtectedMPEG4Video
        case .m4a: return .appleProtectedMPEG4Audio
        case .wav: return .wav
        case .aiff: return .aiff
        }
    }

    /// All content types this app can import
    static var allUTTypes: [UTType] {
        SupportedFormat.allCases.compactMap { $0.utType }
    }

    /// Get compatible output formats for a given input format
    static func compatibleOutputFormats(for input: SupportedFormat) -> [SupportedFormat] {
        let category = input.category
        switch category {
        case .image:
            // Images can convert to any image format (excluding same) + PDF
            var formats = SupportedFormat.allCases.filter { $0.category == .image && $0 != input }
            // Also allow image → PDF
            formats.append(.pdf)
            // Normalize jpg/jpeg — remove duplicate
            if input == .jpg {
                formats.removeAll { $0 == .jpeg }
            } else if input == .jpeg {
                formats.removeAll { $0 == .jpg }
            }
            return formats
        case .document:
            return SupportedFormat.allCases.filter { $0.category == .document && $0 != input }
        case .media:
            // Separate audio and video
            let audioFormats: [SupportedFormat] = [.m4a, .wav, .aiff]
            let videoFormats: [SupportedFormat] = [.mov, .mp4, .m4v]
            if audioFormats.contains(input) {
                return audioFormats.filter { $0 != input }
            } else {
                return videoFormats.filter { $0 != input }
            }
        }
    }

    /// Detect format from a file URL
    static func detect(from url: URL) -> SupportedFormat? {
        let ext = url.pathExtension.lowercased()
        return SupportedFormat.allCases.first { $0.fileExtension == ext }
    }
}

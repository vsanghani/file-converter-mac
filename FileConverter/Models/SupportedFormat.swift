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
    case svg

    // Documents
    case pdf
    case rtf
    case rtfd
    case txt
    case html
    case md
    case csv
    case docx

    // Media
    case mov
    case mp4
    case m4v
    case m4a
    case wav
    case aiff
    case aac
    case flac
    case avi

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
        case .svg: return "SVG"
        case .pdf: return "PDF"
        case .rtf: return "RTF"
        case .rtfd: return "RTFD"
        case .txt: return "Plain Text"
        case .html: return "HTML"
        case .md: return "Markdown"
        case .csv: return "CSV"
        case .docx: return "DOCX"
        case .mov: return "MOV"
        case .mp4: return "MP4"
        case .m4v: return "M4V"
        case .m4a: return "M4A"
        case .wav: return "WAV"
        case .aiff: return "AIFF"
        case .aac: return "AAC"
        case .flac: return "FLAC"
        case .avi: return "AVI"
        }
    }

    var fileExtension: String {
        rawValue
    }

    var category: FileCategory {
        switch self {
        case .png, .jpg, .jpeg, .heic, .heif, .bmp, .tiff, .gif, .webp, .ico, .svg:
            return .image
        case .pdf, .rtf, .rtfd, .txt, .html, .md, .csv, .docx:
            return .document
        case .mov, .mp4, .m4v, .m4a, .wav, .aiff, .aac, .flac, .avi:
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
        case .svg: return UTType(filenameExtension: "svg") ?? UTType("public.svg-image")
        case .pdf: return .pdf
        case .rtf: return .rtf
        case .rtfd: return .rtfd
        case .txt: return .plainText
        case .html: return .html
        case .md: return UTType(filenameExtension: "md") ?? .plainText
        case .csv: return .commaSeparatedText
        case .docx: return UTType(filenameExtension: "docx") ?? UTType("org.openxmlformats.wordprocessingml.document")
        case .mov: return .quickTimeMovie
        case .mp4: return .mpeg4Movie
        case .m4v: return .appleProtectedMPEG4Video
        case .m4a: return .appleProtectedMPEG4Audio
        case .wav: return .wav
        case .aiff: return .aiff
        case .aac: return UTType(filenameExtension: "aac") ?? UTType("public.aac-audio")
        case .flac: return UTType(filenameExtension: "flac") ?? UTType("org.xiph.flac")
        case .avi: return UTType(filenameExtension: "avi") ?? UTType("public.avi")
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
            // Images can convert to any image format (excluding same) + PDF + SVG
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
            // PDF can also export to image formats (per-page)
            if input == .pdf {
                var formats = SupportedFormat.allCases.filter { $0.category == .document && $0 != input }
                // PDF → image (renders each page)
                formats += [.png, .jpg, .tiff]
                return formats
            }
            // DOCX can only convert to plain text formats natively
            if input == .docx {
                return [.txt, .pdf, .html, .rtf]
            }
            return SupportedFormat.allCases.filter { $0.category == .document && $0 != input }
        case .media:
            // Separate audio and video
            let audioFormats: [SupportedFormat] = [.m4a, .aac, .wav, .aiff]
            let videoFormats: [SupportedFormat] = [.mov, .mp4, .m4v, .avi]
            if audioFormats.contains(input) || input == .flac {
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

import Foundation

// MARK: - Conversion Status

enum ConversionStatus: Equatable {
    case pending
    case converting(progress: Double)
    case completed
    case failed(message: String)

    var displayText: String {
        switch self {
        case .pending: return "Pending"
        case .converting(let progress): return "Converting \(Int(progress * 100))%"
        case .completed: return "Completed"
        case .failed(let message): return "Failed: \(message)"
        }
    }

    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .converting: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Conversion Job

class ConversionJob: Identifiable, ObservableObject {
    let id = UUID()
    let sourceURL: URL
    let sourceFormat: SupportedFormat
    let fileName: String
    let fileSize: Int64

    @Published var targetFormat: SupportedFormat
    @Published var status: ConversionStatus = .pending
    @Published var outputURL: URL?

    init(sourceURL: URL, sourceFormat: SupportedFormat, targetFormat: SupportedFormat) {
        self.sourceURL = sourceURL
        self.sourceFormat = sourceFormat
        self.targetFormat = targetFormat
        self.fileName = sourceURL.lastPathComponent

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? Int64) ?? 0
        self.fileSize = fileSize
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

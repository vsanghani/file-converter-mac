import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Main view model coordinating user interactions with the conversion engine
@MainActor
class ConverterViewModel: ObservableObject {

    // MARK: - Published State

    @Published var jobs: [ConversionJob] = []
    @Published var selectedOutputFormat: SupportedFormat?
    @Published var isConverting = false
    @Published var overallProgress: Double = 0
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showCompletionAlert = false
    @Published var completedCount = 0
    @Published var failedCount = 0
    @Published var outputDirectory: URL?

    // MARK: - Private

    private let engine = ConversionEngine()
    private var conversionTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var hasFiles: Bool { !jobs.isEmpty }

    var canConvert: Bool {
        hasFiles && selectedOutputFormat != nil && !isConverting
    }

    var availableOutputFormats: [SupportedFormat] {
        guard let firstJob = jobs.first else { return [] }
        let formats = SupportedFormat.compatibleOutputFormats(for: firstJob.sourceFormat)

        // If all files share the same category, filter to common formats
        let allSameCategory = jobs.allSatisfy { $0.sourceFormat.category == firstJob.sourceFormat.category }
        if allSameCategory {
            return formats
        }

        return formats
    }

    var detectedCategory: FileCategory? {
        jobs.first?.sourceFormat.category
    }

    // MARK: - File Management

    func addFiles(urls: [URL]) {
        for url in urls {
            guard let format = SupportedFormat.detect(from: url) else { continue }

            // Check if a job for this URL already exists
            guard !jobs.contains(where: { $0.sourceURL == url }) else { continue }

            // If we already have files, only allow same category
            if let existingCategory = detectedCategory, format.category != existingCategory {
                errorMessage = "Please add only \(existingCategory.rawValue.lowercased()) files, or clear the list first."
                showError = true
                continue
            }

            let targetFormat = selectedOutputFormat ?? SupportedFormat.compatibleOutputFormats(for: format).first ?? format
            let job = ConversionJob(sourceURL: url, sourceFormat: format, targetFormat: targetFormat)
            jobs.append(job)
        }

        // Auto-select first compatible output format if not set
        if selectedOutputFormat == nil, let firstJob = jobs.first {
            let compatible = SupportedFormat.compatibleOutputFormats(for: firstJob.sourceFormat)
            selectedOutputFormat = compatible.first
        }
    }

    func removeJob(_ job: ConversionJob) {
        jobs.removeAll { $0.id == job.id }
        if jobs.isEmpty {
            selectedOutputFormat = nil
        }
    }

    func clearAll() {
        jobs.removeAll()
        selectedOutputFormat = nil
        overallProgress = 0
        isConverting = false
    }

    // MARK: - Output Format

    func updateOutputFormat(_ format: SupportedFormat) {
        selectedOutputFormat = format
        for job in jobs {
            job.targetFormat = format
        }
    }

    // MARK: - Conversion

    func startConversion() {
        guard canConvert else { return }

        // Determine output directory — same as source file directory
        let outputDir = outputDirectory ?? jobs.first?.sourceURL.deletingLastPathComponent() ?? FileManager.default.temporaryDirectory

        isConverting = true
        overallProgress = 0
        completedCount = 0
        failedCount = 0

        conversionTask = Task {
            let totalJobs = jobs.count

            for (index, job) in jobs.enumerated() {
                guard !Task.isCancelled else { break }

                job.status = .converting(progress: 0)

                do {
                    let outputURL = try await engine.convert(
                        job: job,
                        outputDirectory: outputDir
                    ) { [weak self] progress in
                        Task { @MainActor in
                            job.status = .converting(progress: progress)
                            let baseProgress = Double(index) / Double(totalJobs)
                            let jobContribution = progress / Double(totalJobs)
                            self?.overallProgress = baseProgress + jobContribution
                        }
                    }
                    job.outputURL = outputURL
                    job.status = .completed
                    completedCount += 1
                } catch {
                    job.status = .failed(message: error.localizedDescription)
                    failedCount += 1
                }
            }

            overallProgress = 1.0
            isConverting = false
            showCompletionAlert = true
        }
    }

    func cancelConversion() {
        conversionTask?.cancel()
        isConverting = false
    }

    // MARK: - File Actions

    func revealInFinder(_ job: ConversionJob) {
        guard let url = job.outputURL else { return }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.message = "Choose where to save converted files"
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            outputDirectory = panel.url
        }
    }
}

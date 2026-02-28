import SwiftUI

@main
struct FileConverterApp: App {
    @StateObject private var viewModel = ConverterViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 820, minHeight: 640)
                .onReceive(NotificationCenter.default.publisher(for: .openFiles)) { _ in
                    openFilePicker()
                }
                .onReceive(NotificationCenter.default.publisher(for: .clearAllFiles)) { _ in
                    viewModel.clearAll()
                }
                .onReceive(NotificationCenter.default.publisher(for: .startConversion)) { _ in
                    viewModel.startConversion()
                }
                .onReceive(NotificationCenter.default.publisher(for: .chooseOutputFolder)) { _ in
                    viewModel.chooseOutputDirectory()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Files...") {
                    NotificationCenter.default.post(name: .openFiles, object: nil)
                }
                .keyboardShortcut("o")
            }

            CommandGroup(after: .pasteboard) {
                Divider()
                Button("Clear All Files") {
                    NotificationCenter.default.post(name: .clearAllFiles, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [.command])
            }

            CommandMenu("Convert") {
                Button("Start Conversion") {
                    NotificationCenter.default.post(name: .startConversion, object: nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])

                Button("Choose Output Folder...") {
                    NotificationCenter.default.post(name: .chooseOutputFolder, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = SupportedFormat.allUTTypes
        panel.message = "Select files to convert"

        if panel.runModal() == .OK {
            viewModel.addFiles(urls: panel.urls)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openFiles = Notification.Name("openFiles")
    static let clearAllFiles = Notification.Name("clearAllFiles")
    static let startConversion = Notification.Name("startConversion")
    static let chooseOutputFolder = Notification.Name("chooseOutputFolder")
}

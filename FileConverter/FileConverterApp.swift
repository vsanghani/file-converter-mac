import SwiftUI

@main
struct FileConverterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 650)
        .commands {
            // File menu
            CommandGroup(replacing: .newItem) {
                Button("Open Files...") {
                    NotificationCenter.default.post(name: .openFiles, object: nil)
                }
                .keyboardShortcut("o")
            }

            // Edit menu additions
            CommandGroup(after: .pasteboard) {
                Divider()
                Button("Clear All Files") {
                    NotificationCenter.default.post(name: .clearAllFiles, object: nil)
                }
                .keyboardShortcut(.delete, modifiers: [.command])
            }

            // Custom Convert menu
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
}

// MARK: - Notification Names

extension Notification.Name {
    static let openFiles = Notification.Name("openFiles")
    static let clearAllFiles = Notification.Name("clearAllFiles")
    static let startConversion = Notification.Name("startConversion")
    static let chooseOutputFolder = Notification.Name("chooseOutputFolder")
}

import AppKit
import SwiftUI

@main
struct FolderManifestApp: App {
    @NSApplicationDelegateAdaptor(FolderManifestAppDelegate.self) private var appDelegate
    @StateObject private var languageSettings = LanguageSettings()

    var body: some Scene {
        Window("FolderManifest", id: "main") {
            ContentView()
                .environmentObject(languageSettings)
                .frame(minWidth: 980, minHeight: 680)
                .background(MainWindowAccessor())
        }
        .defaultSize(width: 1180, height: 760)
        .windowStyle(.titleBar)
        .commands {
            FolderManifestCommands(language: languageSettings.language)
        }

        Settings {
            SettingsView()
                .environmentObject(languageSettings)
        }
    }
}

private struct FolderManifestCommands: Commands {
    let language: AppLanguage
    @FocusedValue(\.clearUnpinnedHistoryAction) private var clearUnpinnedHistoryAction
    @FocusedValue(\.openFolderAction) private var openFolderAction

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(strings.openFolderMenu) {
                openFolderAction?.perform()
            }
            .keyboardShortcut("o", modifiers: .command)
            .disabled(openFolderAction == nil)
        }

        CommandGroup(replacing: .saveItem) {
            Divider()
            Button(strings.clearUnpinnedHistory) {
                clearUnpinnedHistoryAction?.perform()
            }
            .disabled(clearUnpinnedHistoryAction == nil)
        }

        CommandGroup(after: .printItem) {
            Divider()
            Button(strings.closeWindow) {
                NSApplication.shared.keyWindow?.performClose(nil)
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(NSApplication.shared.keyWindow == nil)
        }

        CommandGroup(after: .windowList) {
            Button(strings.showMainWindow) {
                MainWindowController.shared.show()
            }
            .keyboardShortcut("0", modifiers: .command)
        }
    }
}

@MainActor
private final class MainWindowController {
    static let shared = MainWindowController()

    private var window: NSWindow?

    func register(_ window: NSWindow) {
        self.window = window
        window.isReleasedWhenClosed = false
    }

    func show() {
        guard let window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

@MainActor
private final class FolderManifestAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            MainWindowController.shared.show()
        }
        return true
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowTrackingView {
        WindowTrackingView()
    }

    func updateNSView(_ nsView: WindowTrackingView, context: Context) { }
}

@MainActor
private final class WindowTrackingView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        MainWindowController.shared.register(window)
    }
}

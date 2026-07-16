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
            CommandGroup(after: .windowList) {
                Button(AppStrings(language: languageSettings.language).showMainWindow) {
                    MainWindowController.shared.show()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(languageSettings)
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

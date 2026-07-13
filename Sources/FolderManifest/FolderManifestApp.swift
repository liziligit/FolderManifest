import SwiftUI

@main
struct FolderManifestApp: App {
    @StateObject private var languageSettings = LanguageSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageSettings)
                .frame(minWidth: 980, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 760)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Settings {
            SettingsView()
                .environmentObject(languageSettings)
        }
    }
}

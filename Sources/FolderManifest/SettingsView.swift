import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings

    private var strings: AppStrings { AppStrings(language: languageSettings.language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(strings.settings)
                .font(.title2.bold())

            Form {
                Picker(strings.languageLabel, selection: $languageSettings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
            }
            .formStyle(.grouped)

            Text(strings.languageHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 460, height: 190)
    }
}

import SwiftUI

/// Pantalla de Ajustes. De momento solo tiene el selector de idioma, pero
/// es el sitio natural donde añadir más preferencias en el futuro.
struct SettingsView: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.appEnvironment) private var appEnvironment

    @State private var languages = WorldLanguages.all()

    var body: some View {
        NavigationStack {
            Form {
                #if DEBUG
                // Visible solo en builds Debug: ayuda a no confundir contra
                // qué entorno se está probando (mock/local/staging/producción).
                Section {
                    LabeledContent("Entorno", value: appEnvironment.displayName)
                }
                #endif

                Section(loc.t("settings.language.section")) {
                    Picker(loc.t("settings.language.current"), selection: languageBinding) {
                        ForEach(languages) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    if loc.isTranslating {
                        HStack {
                            ProgressView()
                            Text(loc.t("settings.language.translating"))
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text(loc.t("settings.language.footer"))
                }
            }
            .navigationTitle(loc.t("settings.navTitle"))
            .alert(
                loc.t("settings.language.errorTitle"),
                isPresented: Binding(
                    get: { loc.translationError != nil },
                    set: { _ in }
                )
            ) {
                Button(loc.t("common.ok")) {}
            } message: {
                Text(loc.translationError ?? "")
            }
        }
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { loc.currentLanguageCode },
            set: { newCode in Task { await loc.setLanguage(newCode) } }
        )
    }
}

#Preview {
    SettingsView()
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}

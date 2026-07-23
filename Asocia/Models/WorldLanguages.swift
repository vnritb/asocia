import Foundation

struct AppLanguage: Identifiable, Hashable {
    var code: String
    var name: String
    var id: String { code }
}

/// Genera la lista de idiomas del selector de Ajustes, en el orden pedido:
/// 1) español, catalán, gallego, euskera, inglés (idiomas oficiales de
///    España + inglés, siempre los primeros).
/// 2) los 10 idiomas más hablados del mundo por número total de hablantes
///    (Ethnologue 2025: inglés, chino mandarín, hindi, español, árabe,
///    francés, bengalí, portugués, ruso, indonesio — quitando inglés y
///    español, que ya están arriba, y completando hasta 10 con urdu y
///    alemán, siguientes en el ranking).
/// 3) el resto de idiomas del mundo (código ISO 639-1), por orden
///    alfabético de su nombre en español.
///
/// Los nombres se generan con `Locale`, no están escritos a mano: así la
/// lista cubre TODOS los idiomas que conoce el sistema operativo sin
/// mantener una tabla gigante a mano.
enum WorldLanguages {

    static let priorityCodes = [
        "es", "ca", "gl", "eu", "en",
        "zh", "hi", "ar", "fr", "bn", "pt", "ru", "id", "ur", "de"
    ]

    static func all(displayLocale: Locale = Locale(identifier: "es")) -> [AppLanguage] {
        var seen = Set<String>()

        let priority: [AppLanguage] = priorityCodes.compactMap { code in
            guard seen.insert(code).inserted else { return nil }
            return AppLanguage(code: code, name: displayName(for: code, in: displayLocale))
        }

        let allCodes = Locale.LanguageCode.isoLanguageCodes.map(\.identifier)
        let rest: [AppLanguage] = allCodes
            .filter { !seen.contains($0) && $0.count == 2 } // nos quedamos con ISO 639-1 (2 letras)
            .compactMap { code -> AppLanguage? in
                let name = displayName(for: code, in: displayLocale)
                guard name != code else { return nil } // descarta códigos sin nombre legible
                seen.insert(code)
                return AppLanguage(code: code, name: name)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return priority + rest
    }

    private static func displayName(for code: String, in locale: Locale) -> String {
        let raw = locale.localizedString(forLanguageCode: code) ?? code
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

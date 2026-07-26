import Foundation

struct AppLanguage: Identifiable, Hashable {
    var code: String
    var name: String
    var id: String { code }
}

/// Genera la lista de idiomas del selector de Ajustes.
/// La app solo soporta 5 idiomas con localizaciones completas:
/// español, catalán, gallego, euskera e inglés (idiomas oficiales de
/// España + inglés para cobertura internacional).
///
/// Los nombres se generan con `Locale`, no están escritos a mano.
enum WorldLanguages {

    /// Los 5 idiomas soportados por la app
    static let priorityCodes = [
        "es", "ca", "gl", "eu", "en"
    ]

    /// Devuelve solo los idiomas soportados, en el orden definido arriba
    static func all(displayLocale: Locale = Locale(identifier: "es")) -> [AppLanguage] {
        priorityCodes.map { code in
            AppLanguage(code: code, name: displayName(for: code, in: displayLocale))
        }
    }

    private static func displayName(for code: String, in locale: Locale) -> String {
        let raw = locale.localizedString(forLanguageCode: code) ?? code
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

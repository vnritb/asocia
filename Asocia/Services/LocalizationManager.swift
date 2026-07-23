import Foundation

/// Fuente de verdad de los textos de la interfaz.
///
/// El español (`es`) es el idioma base: sus textos viven empaquetados en
/// `Resources/Localization/es.json` y son los que se envían al backend para
/// traducir. Cambiar de idioma NO usa el mecanismo estándar de Xcode
/// (String Catalogs / .lproj), porque ese mecanismo se resuelve en tiempo
/// de compilación y aquí necesitamos poder añadir idiomas nuevos en tiempo
/// de ejecución (cualquier idioma del mundo, traducido bajo demanda por
/// IA). En su lugar, `strings` es un diccionario en memoria que se
/// recarga cuando el usuario cambia de idioma en Ajustes.
@MainActor
@Observable
final class LocalizationManager {

    static let baseLanguageCode = "es"

    private(set) var currentLanguageCode: String
    private(set) var strings: [String: String]
    private(set) var isTranslating = false
    private(set) var translationError: String?

    private let baseStrings: [String: String]
    private let translationClient: TranslationServicing
    private let cacheDirectory: URL
    private let preferenceKey = "org.itb.asocia.languageCode"

    init(translationClient: TranslationServicing) {
        self.translationClient = translationClient
        let base = Self.loadBundledDictionary(languageCode: Self.baseLanguageCode) ?? [:]
        self.baseStrings = base
        self.strings = base
        self.currentLanguageCode = Self.baseLanguageCode

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = support.appendingPathComponent("Localization", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        if let savedCode = UserDefaults.standard.string(forKey: preferenceKey), savedCode != Self.baseLanguageCode {
            applyStoredLanguageIfAvailable(savedCode)
        }
    }

    /// Traduce la clave `key` al idioma actual; si falta, cae al español
    /// base y, en último caso, devuelve la propia clave (visible en debug,
    /// nunca debería verse en producción).
    func t(_ key: String) -> String {
        strings[key] ?? baseStrings[key] ?? key
    }

    /// Como `t(_:)` pero con un entero para formatos tipo "%d seleccionados".
    func t(_ key: String, count: Int) -> String {
        let format = strings[key] ?? baseStrings[key] ?? key
        return String(format: format, count)
    }

    /// Cambia el idioma activo. Si ya está cacheado en disco (o es el
    /// español base), el cambio es instantáneo; si no, dispara la
    /// traducción vía IA en el backend y cachea el resultado.
    func setLanguage(_ code: String) async {
        guard code != currentLanguageCode else { return }

        if code == Self.baseLanguageCode {
            strings = baseStrings
            currentLanguageCode = code
            UserDefaults.standard.set(code, forKey: preferenceKey)
            return
        }

        if let bundled = Self.loadBundledDictionary(languageCode: code) {
            strings = bundled
            currentLanguageCode = code
            UserDefaults.standard.set(code, forKey: preferenceKey)
            return
        }

        if let cached = loadDiskCache(code: code) {
            strings = cached
            currentLanguageCode = code
            UserDefaults.standard.set(code, forKey: preferenceKey)
            return
        }

        isTranslating = true
        translationError = nil
        defer { isTranslating = false }

        do {
            let translated = try await translationClient.translate(strings: baseStrings, to: code)
            strings = translated
            currentLanguageCode = code
            saveDiskCache(code: code, dict: translated)
            UserDefaults.standard.set(code, forKey: preferenceKey)
        } catch {
            translationError = error.localizedDescription
        }
    }

    // MARK: - Carga

    private func applyStoredLanguageIfAvailable(_ code: String) {
        if let bundled = Self.loadBundledDictionary(languageCode: code) {
            strings = bundled
            currentLanguageCode = code
        } else if let cached = loadDiskCache(code: code) {
            strings = cached
            currentLanguageCode = code
        }
        // Si no hay ni bundle ni caché (p.ej. tras reinstalar la app),
        // se queda en español hasta que el usuario vuelva a elegir el
        // idioma desde Ajustes, que disparará la traducción de nuevo.
    }

    private static func loadBundledDictionary(languageCode: String) -> [String: String]? {
        // Según cómo XcodeGen añada la carpeta Resources/Localization al
        // bundle (referencia de carpeta vs. grupo con ficheros sueltos), el
        // JSON puede acabar dentro de un subdirectorio "Localization" o
        // directamente en la raíz del bundle. Se prueban ambas rutas.
        let url = Bundle.main.url(forResource: languageCode, withExtension: "json", subdirectory: "Localization")
            ?? Bundle.main.url(forResource: languageCode, withExtension: "json")
        guard let url,
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else { return nil }
        return dict
    }

    private func loadDiskCache(code: String) -> [String: String]? {
        let url = cacheDirectory.appendingPathComponent("\(code).json")
        guard let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else { return nil }
        return dict
    }

    private func saveDiskCache(code: String, dict: [String: String]) {
        let url = cacheDirectory.appendingPathComponent("\(code).json")
        guard let data = try? JSONEncoder().encode(dict) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

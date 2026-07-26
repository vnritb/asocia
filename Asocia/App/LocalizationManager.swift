import Foundation
import Observation

/// Gestor de localización que proporciona textos estáticos en 5 idiomas:
/// español, catalán, gallego, euskera e inglés.
/// Permite cambiar el idioma de la app en tiempo de ejecución sin necesidad de reiniciar.
@Observable
@MainActor
class LocalizationManager {
    
    // MARK: - Properties
    
    /// Código del idioma actual (ISO 639-1: "es", "ca", "gl", "eu", "en")
    private(set) var currentLanguageCode: String {
        didSet {
            UserDefaults.standard.set(currentLanguageCode, forKey: "AppLanguage")
        }
    }
    
    /// Diccionario de localizaciones cargado desde archivos JSON
    /// [código idioma: [clave: texto]]
    private var translations: [String: [String: String]] = [:]
    
    /// Idiomas soportados
    private let supportedLanguages = ["es", "ca", "gl", "eu", "en"]
    
    // MARK: - Initialization
    
    init() {
        // Primero inicializar currentLanguageCode
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguageCode = savedLanguage
        } else {
            // Detectar idioma del sistema
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "es"
            // Verificar que el idioma del sistema sea uno de los soportados
            self.currentLanguageCode = supportedLanguages.contains(systemLanguage) ? systemLanguage : "es"
        }
        
        // Ahora cargar las traducciones después de que todas las propiedades estén inicializadas
        loadTranslations()
    }
    
    // MARK: - Private Methods
    
    /// Carga las traducciones desde los archivos JSON en el bundle principal
    private func loadTranslations() {
        for languageCode in supportedLanguages {
            guard let url = Bundle.main.url(forResource: languageCode, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let dictionary = try? JSONDecoder().decode([String: String].self, from: data) else {
                print("⚠️ No se pudo cargar el archivo de localización para '\(languageCode)'")
                continue
            }
            translations[languageCode] = dictionary
        }
        
        #if DEBUG
        print("✅ Localizaciones cargadas: \(translations.keys.sorted().joined(separator: ", "))")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Cambia el idioma actual
    /// - Parameter code: Código ISO 639-1 del idioma (ej: "es", "ca", "gl", "eu", "en")
    func setLanguage(_ code: String) {
        currentLanguageCode = code
    }
    
    /// Traduce una clave al idioma actual
    /// - Parameter key: Clave de localización en formato punto (ej: "chatList.navTitle")
    /// - Parameter count: Parámetro opcional para pluralización
    /// - Returns: Texto localizado o la clave si no existe traducción
    func t(_ key: String, count: Int? = nil) -> String {
        let baseTranslation = translations[currentLanguageCode]?[key] ?? translations["es"]?[key] ?? key
        
        // Si se proporciona un count, intentar reemplazar placeholders con formato %d
        if let count = count {
            return String(format: baseTranslation, count)
        }
        
        return baseTranslation
    }
}

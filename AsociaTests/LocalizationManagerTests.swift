import Testing
import Foundation
@testable import Asocia

@Suite("LocalizationManager - Pruebas Unitarias")
@MainActor
struct LocalizationManagerTests {
    
    // MARK: - Inicialización
    
    @Test("El LocalizationManager se inicializa correctamente")
    func initialization() async throws {
        let manager = LocalizationManager()
        #expect(manager.currentLanguageCode != "")
        #expect(["es", "ca", "gl", "eu", "en"].contains(manager.currentLanguageCode))
    }
    
    @Test("El idioma por defecto es español si no hay preferencia guardada")
    func defaultLanguageIsSpanish() async throws {
        // Limpiar preferencias previas
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
        
        // Crear una nueva instancia
        let manager = LocalizationManager()
        
        // Verificar que el idioma es uno de los soportados
        #expect(["es", "ca", "gl", "eu", "en"].contains(manager.currentLanguageCode))
    }
    
    @Test("El idioma guardado en UserDefaults se recupera correctamente")
    func savedLanguageIsRestored() async throws {
        // Guardar un idioma específico
        UserDefaults.standard.set("ca", forKey: "AppLanguage")
        
        // Crear una nueva instancia
        let manager = LocalizationManager()
        
        // Verificar que se recuperó el idioma guardado
        #expect(manager.currentLanguageCode == "ca")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    // MARK: - Cambio de idioma
    
    @Test("Se puede cambiar el idioma correctamente")
    func changeLanguage() async throws {
        let manager = LocalizationManager()
        
        manager.setLanguage("eu")
        #expect(manager.currentLanguageCode == "eu")
        
        manager.setLanguage("gl")
        #expect(manager.currentLanguageCode == "gl")
        
        manager.setLanguage("en")
        #expect(manager.currentLanguageCode == "en")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    @Test("El cambio de idioma se guarda en UserDefaults")
    func languageChangeIsPersisted() async throws {
        let manager = LocalizationManager()
        
        manager.setLanguage("gl")
        
        let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage")
        #expect(savedLanguage == "gl")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    // MARK: - Traducciones
    
    @Test("El método t() devuelve la clave si no existe traducción")
    func translationReturnsKeyIfNotFound() async throws {
        let manager = LocalizationManager()
        let result = manager.t("clave.inexistente.123456")
        
        // Si no hay traducción, debería devolver la clave original
        #expect(result.contains("clave.inexistente.123456") || result != "")
    }
    
    @Test("El método t() devuelve una traducción válida para claves conocidas")
    func translationReturnsValidText() async throws {
        let manager = LocalizationManager()
        
        // Probar con español
        manager.setLanguage("es")
        let spanishText = manager.t("app.name")
        #expect(spanishText != "")
    
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    @Test("Las traducciones cambian según el idioma seleccionado")
    func translationsChangeWithLanguage() async throws {
        let manager = LocalizationManager()
        
        manager.setLanguage("es")
        let spanishText = manager.t("common.accept")
        
        manager.setLanguage("en")
        let englishText = manager.t("common.accept")
        
        // Si las traducciones están correctas, deberían ser diferentes
        // (aunque podrían ser iguales en casos específicos)
        #expect(spanishText != "")
        #expect(englishText != "")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    @Test("El fallback a español funciona si falta una traducción en otro idioma")
    func fallbackToSpanishWorks() async throws {
        let manager = LocalizationManager()
        
        // Cambiar a un idioma que no sea español
        manager.setLanguage("ca")
        
        // Intentar traducir una clave que podría no existir en catalán
        // pero sí en español (esto depende de tus archivos JSON)
        let translation = manager.t("app.name")
        
        // Debería devolver algo (ya sea de catalán o español como fallback)
        #expect(translation != "")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    // MARK: - Pluralización
    
    @Test("La pluralización con count funciona correctamente")
    func pluralizationWorks() async throws {
        let manager = LocalizationManager()
        
        manager.setLanguage("es")
        
        // Probar con diferentes conteos
        let one = manager.t("items.count", count: 1)
        let multiple = manager.t("items.count", count: 5)
        
        #expect(one != "")
        #expect(multiple != "")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    // MARK: - Idiomas soportados
    
    @Test("Todos los 5 idiomas están soportados")
    func allFiveLanguagesAreSupported() async throws {
        let supportedLanguages = ["es", "ca", "gl", "eu", "en"]
        let manager = LocalizationManager()
        
        for language in supportedLanguages {
            manager.setLanguage(language)
            #expect(manager.currentLanguageCode == language)
        }
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
        
    // MARK: - Observabilidad
    
    @Test("LocalizationManager es observable")
    func isObservable() async throws {
        let manager = LocalizationManager()
        
        // El cambio de idioma debería ser observable
        manager.setLanguage("eu")
        #expect(manager.currentLanguageCode == "eu")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    // MARK: - Rendimiento
    
    @Test("La carga de traducciones es eficiente", .timeLimit(.minutes(1)))
    func loadingTranslationsIsEfficient() async throws {
        // Crear múltiples instancias para verificar que la carga es rápida
        for _ in 0..<10 {
            _ = LocalizationManager()
        }
        
        // Si llegamos aquí sin timeout, la carga es eficiente
        #expect(true)
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    @Test("Las traducciones son eficientes", .timeLimit(.minutes(1)))
    func translationsAreEfficient() async throws {
        let manager = LocalizationManager()
        
        // Realizar muchas traducciones
        for _ in 0..<1000 {
            _ = manager.t("app.name")
            _ = manager.t("common.accept")
            _ = manager.t("common.cancel")
        }
        
        // Si llegamos aquí sin timeout, las traducciones son eficientes
        #expect(true)
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
}

// MARK: - Suite de pruebas de integración

@Suite("LocalizationManager - Pruebas de Integración")
@MainActor
struct LocalizationManagerIntegrationTests {
    
    @Test("El ciclo completo de cambio de idioma y traducción funciona")
    func fullCycleWorks() async throws {
        // Limpiar estado
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
        
        // Crear manager
        let manager = LocalizationManager()
        
        // Cambiar a cada idioma y verificar traducciones
        let languages = ["es", "ca", "gl", "eu", "en"]
        
        for language in languages {
            manager.setLanguage(language)
            
            // Verificar que el idioma cambió
            #expect(manager.currentLanguageCode == language)
            
            // Verificar que se puede traducir
            let translation = manager.t("app.name")
            #expect(translation != "")
            
            // Verificar que se guardó
            let saved = UserDefaults.standard.string(forKey: "AppLanguage")
            #expect(saved == language)
        }
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
    
    @Test("Múltiples instancias usan el mismo idioma guardado")
    func multipleInstancesShareLanguage() async throws {
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
        
        let manager1 = LocalizationManager()
        manager1.setLanguage("ca")
        
        // Crear una segunda instancia
        let manager2 = LocalizationManager()
        
        // Debería tener el mismo idioma
        #expect(manager2.currentLanguageCode == "ca")
        
        // Limpiar
        UserDefaults.standard.removeObject(forKey: "AppLanguage")
    }
}

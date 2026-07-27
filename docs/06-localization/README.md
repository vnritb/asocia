# 🌍 Localización - Asocia

Sistema multiidioma (5 idiomas soportados).

---

## 📄 Documentos en esta Sección

### [LOCALIZATION_GUIDE.md](./LOCALIZATION_GUIDE.md) ✨
**Guía Completa Unificada de Localización**

Guía definitiva que cubre todo sobre el sistema de localización:
- 🌍 5 idiomas soportados (es, ca, gl, eu, en)
- ⚙️ Configuración inicial
- 🧪 39 pruebas automatizadas (19 unitarias + 20 UI)
- 🐛 Solución de problemas
- 💻 Ejemplos de uso en código
- 📚 Referencias y recursos

**Este documento reemplaza y unifica:**
- ~~LOCALIZATION_SETUP_CHECKLIST.md~~ (eliminado)
- ~~LOCALIZATION_TESTING_GUIDE.md~~ (eliminado)

---

## 🌍 Idiomas Soportados

| Idioma | Código | Emoji | Estado |
|--------|--------|-------|--------|
| **Español** | `es` | 🇪🇸 | Por defecto ✅ |
| **Catalán** | `ca` | 🇨🇦 | Completo ✅ |
| **Gallego** | `gl` | 🇪🇸 | Completo ✅ |
| **Euskera** | `eu` | 🇪🇸 | Completo ✅ |
| **Inglés** | `en` | 🇬🇧 | Completo ✅ |

---

## 🎯 Inicio Rápido

### 1. Verificar Archivos JSON

```bash
# Desde la raíz del proyecto
ls -la Resources/*.json

# Deberías ver:
# es.json
# ca.json
# gl.json
# eu.json
# en.json
```

### 2. Usar en una Vista

```swift
struct MyView: View {
    @Environment(LocalizationManager.self) private var loc
    
    var body: some View {
        VStack {
            Text(loc.t("welcome.message"))
            Text(loc.t("items.count", count: 5))
        }
    }
}
```

### 3. Cambiar Idioma

```swift
Task {
    await loc.setLanguage("ca")  // Catalán
}
```

---

## 🧪 Testing

### Ejecutar Todas las Pruebas

```bash
# 19 pruebas unitarias + 20 pruebas de UI = 39 total
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Solo Pruebas de Localización

```bash
# Unitarias
xcodebuild test -scheme Asocia \
  -only-testing:AsociaTests/LocalizationManagerTests

# UI
xcodebuild test -scheme Asocia \
  -only-testing:AsociaUITests/LocalizationManagerUITests
```

---

## 🏗️ Arquitectura

### LocalizationManager

```swift
@Observable
final class LocalizationManager {
    static let availableLanguages = ["es", "ca", "gl", "eu", "en"]
    
    var currentLanguage: String
    
    func t(_ key: String, count: Int? = nil) -> String
    func setLanguage(_ code: String) async
}
```

### Archivos JSON

```json
{
  "app.name": "Asocia",
  "welcome.message": "Bienvenido",
  "items.count": "%d elementos",
  "common.accept": "Aceptar"
}
```

### Integración

```swift
// AsociaApp.swift
@State private var localizationManager = LocalizationManager()

var body: some Scene {
    WindowGroup {
        RootView()
            .environment(localizationManager)
    }
}
```

---

## ❓ Problemas Comunes

### ⚠️ "No se pudo cargar el archivo de localización"

**Solución:**
1. Verificar que el archivo JSON existe en `Resources/`
2. En Xcode, verificar que el archivo está en el target
3. Build Phases → Copy Bundle Resources → Verificar que aparece

### ❌ Las traducciones no cambian

**Solución:**
1. Verificar que `LocalizationManager` es `@Observable`
2. Verificar que está en el environment
3. Usar `loc.t()` no texto hardcodeado

### 🔍 Ver qué está cargado

```swift
// En la consola al iniciar la app
✅ Localizaciones cargadas: ca, en, es, eu, gl
```

---

## 📊 Cobertura de Tests

| Categoría | Tests | Framework |
|-----------|-------|-----------|
| Inicialización | 3 | Swift Testing |
| Cambio de idioma | 2 | Swift Testing |
| Traducciones | 4 | Swift Testing |
| Pluralización | 1 | Swift Testing |
| Idiomas soportados | 2 | Swift Testing |
| Observabilidad | 1 | Swift Testing |
| Rendimiento | 2 | Swift Testing |
| Integración | 2 | Swift Testing |
| **Subtotal Unitarias** | **19** | - |
| UI básica | 6 | XCTest |
| UI dinámica | 2 | XCTest |
| Todos los idiomas | 1 | XCTest |
| Formularios | 3 | XCTest |
| Navegación | 1 | XCTest |
| Accesibilidad | 1 | XCTest |
| Rendimiento UI | 1 | XCTest |
| Casos extremos | 2 | XCTest |
| **Subtotal UI** | **20** | - |
| **TOTAL** | **39** | - |

---

## 🔗 Enlaces Relacionados

- **Guía Completa**: [LOCALIZATION_GUIDE.md](./LOCALIZATION_GUIDE.md) ← **Leer primero**
- **Testing en General**: Ver tests en `AsociaTests/` y `AsociaUITests/`

---

**Última actualización:** 27 de julio de 2026  
**Documentos unificados:** v2.0

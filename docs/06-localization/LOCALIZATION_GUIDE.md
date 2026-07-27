# 🌍 Guía Completa de Localización - LocalizationManager

**Versión:** 2.0  
**Fecha:** 27 de julio de 2026

Esta guía unifica toda la información sobre el sistema de localización de Asocia, incluyendo configuración, pruebas y solución de problemas.

---

## 📚 Tabla de Contenidos

1. [Resumen del Sistema](#-resumen-del-sistema)
2. [Configuración Inicial](#-configuración-inicial)
3. [Pruebas del Sistema](#-pruebas-del-sistema)
4. [Solución de Problemas](#-solución-de-problemas)
5. [Uso en Código](#-uso-en-código)
6. [Referencias](#-referencias)

---

## 🎯 Resumen del Sistema

El `LocalizationManager` es el sistema de internacionalización de Asocia que soporta **5 idiomas**:

- 🇪🇸 **Español** (es) - Idioma por defecto
- 🇨🇦 **Catalán** (ca)
- 🇪🇸 **Gallego** (gl)
- 🇪🇸 **Euskera** (eu)
- 🇬🇧 **Inglés** (en)

### Características

- ✅ **Observable** - Los cambios de idioma actualizan la UI automáticamente
- ✅ **Persistente** - El idioma seleccionado se guarda en UserDefaults
- ✅ **Fallback** - Si falta una traducción, usa español como respaldo
- ✅ **Pluralización** - Soporte para contadores con `count`
- ✅ **Testeable** - 39 pruebas automatizadas (19 unitarias + 20 UI)

---

## ⚙️ Configuración Inicial

### 1. Estructura de Archivos

```
Asocia/
├── App/
│   ├── AsociaApp.swift ✅
│   └── LocalizationManager-App.swift ✅
├── Resources/
│   ├── es.json ⚠️ (verificar)
│   ├── ca.json ⚠️ (verificar)
│   ├── gl.json ⚠️ (verificar)
│   ├── eu.json ⚠️ (verificar)
│   └── en.json ⚠️ (verificar)
├── AsociaTests/
│   └── LocalizationManagerTests.swift ✅
└── AsociaUITests/
    └── LocalizationManagerUITests.swift ✅
```

### 2. Archivos JSON de Traducciones

Cada archivo debe estar en `Resources/` con el formato:

```json
{
  "app.name": "Asocia",
  "common.accept": "Aceptar",
  "common.cancel": "Cancelar",
  "items.count": "%d elementos",
  "welcome.message": "Bienvenido a Asocia"
}
```

**Verificar que los archivos:**
- Existen en la carpeta `Resources/`
- Están incluidos en el target de la app (File Inspector → Target Membership)
- Aparecen en Build Phases → Copy Bundle Resources
- Tienen formato JSON válido (usa [jsonlint.com](https://jsonlint.com))

### 3. Integración en AsociaApp.swift

El archivo `AsociaApp.swift` debe tener:

```swift
@State private var localizationManager = LocalizationManager()

var body: some Scene {
    WindowGroup {
        RootView()
            .environment(localizationManager)
        // ...
    }
}
```

Y soporte para UI tests:

```swift
if let languageIndex = CommandLine.arguments.firstIndex(of: "-UITEST_LANGUAGE"),
   languageIndex + 1 < CommandLine.arguments.count {
    let language = CommandLine.arguments[languageIndex + 1]
    UserDefaults.standard.set(language, forKey: "AppLanguage")
    print("🧪 UI Test: Idioma configurado a '\(language)'")
}
```

---

## 🧪 Pruebas del Sistema

### Estadísticas de Cobertura

| Tipo | Cantidad | Framework |
|------|----------|-----------|
| **Pruebas Unitarias** | 19 tests | Swift Testing |
| **Pruebas de UI** | 20 tests | XCTest UI Testing |
| **Total** | **39 tests** | - |

---

### 📋 Pruebas Unitarias (Swift Testing)

**Ubicación:** `AsociaTests/LocalizationManagerTests.swift`

#### Cobertura Detallada

##### 1. Inicialización (3 pruebas)
- ✅ LocalizationManager se inicializa correctamente
- ✅ Idioma por defecto es español si no hay preferencia
- ✅ Idioma guardado en UserDefaults se recupera

##### 2. Cambio de idioma (2 pruebas)
- ✅ Se puede cambiar el idioma
- ✅ El cambio se guarda en UserDefaults

##### 3. Traducciones (4 pruebas)
- ✅ `t()` devuelve la clave si no existe traducción
- ✅ `t()` devuelve traducción válida para claves conocidas
- ✅ Las traducciones cambian según el idioma
- ✅ Fallback a español funciona correctamente

##### 4. Pluralización (1 prueba)
- ✅ Pluralización con `count` funciona

##### 5. Idiomas soportados (2 pruebas)
- ✅ Todos los 5 idiomas están soportados
- ✅ Códigos de idioma son ISO 639-1 válidos

##### 6. Observabilidad (1 prueba)
- ✅ LocalizationManager es observable

##### 7. Rendimiento (2 pruebas)
- ✅ Carga de traducciones es eficiente
- ✅ Traducciones son rápidas

##### 8. Integración (2 pruebas)
- ✅ Ciclo completo funciona
- ✅ Múltiples instancias usan el mismo idioma

#### Ejecutar Pruebas Unitarias

```bash
# Desde Xcode
⌘ + U (Command + U)

# Desde terminal - todas las unitarias
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AsociaTests/LocalizationManagerTests

# Una prueba específica
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AsociaTests/LocalizationManagerTests/changeLanguage
```

---

### 🖥️ Pruebas de UI (XCTest)

**Ubicación:** `AsociaUITests/LocalizationManagerUITests.swift`

#### Cobertura Detallada

##### 1. Pruebas básicas de idioma (6 pruebas)
- ✅ App muestra textos en idioma por defecto
- ✅ Se puede cambiar a español
- ✅ Se puede cambiar a catalán
- ✅ Se puede cambiar a gallego
- ✅ Se puede cambiar a euskera
- ✅ Se puede cambiar a inglés

##### 2. Cambio dinámico (2 pruebas)
- ✅ Idioma cambia en tiempo real
- ✅ Idioma persiste entre reinicios

##### 3. Todos los idiomas (1 prueba)
- ✅ Los 5 idiomas funcionan correctamente

##### 4. Formularios multiidioma (3 pruebas)
- ✅ Formulario en español
- ✅ Formulario en catalán
- ✅ Formulario en inglés

##### 5. Navegación (1 prueba)
- ✅ Navegación funciona en todos los idiomas

##### 6. Accesibilidad (1 prueba)
- ✅ Identificadores independientes del idioma

##### 7. Rendimiento (1 prueba)
- ✅ Cambio de idioma es rápido

##### 8. Casos extremos (2 pruebas)
- ✅ Maneja idiomas no soportados
- ✅ Maneja idioma vacío

#### Ejecutar Pruebas de UI

```bash
# Desde Xcode
⌘ + U en el target AsociaUITests

# Desde terminal - todas las UI tests
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AsociaUITests/LocalizationManagerUITests

# Una prueba específica
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AsociaUITests/LocalizationManagerUITests/testChangeLanguageToSpanish
```

#### Argumentos de Lanzamiento para UI Tests

```swift
// Resetear estado y configurar idioma
app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
app.launchArguments += ["-UITEST_LANGUAGE", "ca"]
app.launch()
```

**Argumentos disponibles:**
- `-UITEST_RESET_STATE` - Limpia UserDefaults y usa contenedor en memoria
- `-UITEST_LANGUAGE <código>` - Configura idioma inicial (es, ca, gl, eu, en)
- `-UITEST_CLEAR_LANGUAGE` - Limpia idioma guardado

---

### 🚀 Ejecutar Todas las Pruebas

```bash
# Compilar el proyecto
xcodebuild -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# Ejecutar TODAS las pruebas (unitarias + UI)
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Solo LocalizationManager (unitarias + UI)
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AsociaTests/LocalizationManagerTests \
  -only-testing:AsociaUITests/LocalizationManagerUITests

# Con cobertura de código
xcodebuild test -scheme Asocia \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES
```

---

## 🐛 Solución de Problemas

### Error: "Unable to find module dependency: 'Testing'"

**Problema:** Imports explícitos innecesarios

**Solución:**
```swift
// ❌ NO HACER
import Testing  // Eliminar esta línea

// ✅ CORRECTO para unit tests
import Foundation
@testable import Asocia

@Suite("Mi Test Suite")
struct MiTest {
    @Test func miPrueba() {
        #expect(true)
    }
}
```

```swift
// ✅ CORRECTO para UI tests
@MainActor
final class MiUITest: XCTestCase {
    func testAlgo() {
        XCTAssertTrue(true)
    }
}
```

**Nota:** Los frameworks `Testing` y `XCTest` ya están disponibles implícitamente en este proyecto.

---

### Error: "Cannot find 'LocalizationManager' in scope"

**Problema:** Target de tests no puede importar Asocia

**Solución:**
1. Verifica que `LocalizationManager-App.swift` está en el target Asocia
2. Verifica que la clase no sea `private`
3. Asegúrate de tener `@testable import Asocia` en el archivo de tests
4. En File Inspector, marca el target membership correcto

---

### Error: "No such file 'es.json'" o "⚠️ No se pudo cargar el archivo de localización"

**Problema:** Archivos JSON no están en el bundle

**Solución:**
1. Verifica que los 5 archivos JSON existen en `Resources/`
2. Selecciona cada archivo JSON en Xcode
3. En File Inspector (panel derecho), marca el checkbox del target **Asocia**
4. Verifica en Build Phases → Copy Bundle Resources que aparecen:
   - `es.json`
   - `ca.json`
   - `gl.json`
   - `eu.json`
   - `en.json`
5. Valida el formato JSON en [jsonlint.com](https://jsonlint.com)

---

### Las pruebas de UI fallan con timeout

**Problema:** Elementos no se encuentran en la UI

**Solución:**
1. Ejecuta en modo debug para ver la jerarquía de vistas
2. Aumenta el timeout: `element.waitForExistence(timeout: 10)`
3. Verifica identificadores de accesibilidad:
   ```swift
   TextField("Nombre", text: $name)
       .accessibilityIdentifier("signup_firstName")
   ```
4. Limpia derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*
   ```

---

### Las traducciones no cambian en tiempo real

**Problema:** Al cambiar idioma, los textos no se actualizan

**Solución:**
1. Verifica que `LocalizationManager` es `@Observable`:
   ```swift
   @Observable
   final class LocalizationManager { ... }
   ```

2. Verifica inyección en environment:
   ```swift
   @State private var localizationManager = LocalizationManager()
   
   var body: some Scene {
       WindowGroup {
           RootView()
               .environment(localizationManager)
       }
   }
   ```

3. Usa el manager correctamente en las vistas:
   ```swift
   @Environment(LocalizationManager.self) private var loc
   
   var body: some View {
       Text(loc.t("welcome.message"))  // ✅ Correcto
       // NO: Text("Welcome")          // ❌ Hardcoded
   }
   ```

---

### Warning al ejecutar la app: "No se pudo cargar..."

**Problema:** Un archivo JSON no se encuentra o tiene formato incorrecto

**Diagnóstico:**
```
✅ Localizaciones cargadas: ca, en, es    ← Solo 3 de 5
⚠️ No se pudo cargar el archivo de localización para 'gl'
⚠️ No se pudo cargar el archivo de localización para 'eu'
```

**Solución:**
1. Verifica que `gl.json` y `eu.json` existen en Resources
2. Valida el formato JSON
3. Asegúrate de que están incluidos en el target
4. Reinicia Xcode si es necesario

---

### Limpiar build y derivedData

```bash
# Limpiar proyecto
xcodebuild clean -scheme Asocia

# Eliminar derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*

# Reiniciar simulador
xcrun simctl shutdown all
xcrun simctl erase all
```

---

## 💻 Uso en Código

### Inicialización

```swift
// En AsociaApp.swift
@State private var localizationManager = LocalizationManager()

var body: some Scene {
    WindowGroup {
        RootView()
            .environment(localizationManager)
    }
}
```

### En las Vistas

```swift
struct MyView: View {
    @Environment(LocalizationManager.self) private var loc
    
    var body: some View {
        VStack {
            // Traducción simple
            Text(loc.t("welcome.message"))
            
            // Traducción con pluralización
            Text(loc.t("items.count", count: 5))
            
            // Botón
            Button(loc.t("common.accept")) {
                // Acción
            }
        }
    }
}
```

### Cambiar Idioma

```swift
struct LanguageSelector: View {
    @Environment(LocalizationManager.self) private var loc
    
    var body: some View {
        Picker("Idioma", selection: Binding(
            get: { loc.currentLanguage },
            set: { newLanguage in
                Task {
                    await loc.setLanguage(newLanguage)
                }
            }
        )) {
            Text("Español").tag("es")
            Text("Català").tag("ca")
            Text("Galego").tag("gl")
            Text("Euskara").tag("eu")
            Text("English").tag("en")
        }
    }
}
```

### Idiomas Disponibles

```swift
// Obtener lista de idiomas
let languages = LocalizationManager.availableLanguages
// ["es", "ca", "gl", "eu", "en"]

// Verificar si un idioma está soportado
if LocalizationManager.availableLanguages.contains("ca") {
    // Catalán está disponible
}
```

---

## ✅ Checklist de Verificación

### Antes de Ejecutar Pruebas

- [ ] Los 5 archivos JSON existen en `Resources/`
- [ ] Los archivos JSON tienen formato válido
- [ ] Los archivos JSON están incluidos en el target Asocia
- [ ] `AsociaApp.swift` tiene soporte para `-UITEST_LANGUAGE`
- [ ] `LocalizationManager.swift` es `@Observable`
- [ ] Los archivos de pruebas están en los targets correctos

### Verificación en Runtime

1. **Ejecutar la app**
2. **Revisar consola** - Busca:
   ```
   ✅ Localizaciones cargadas: ca, en, es, eu, gl
   ```
3. **Si hay warnings:**
   ```
   ⚠️ No se pudo cargar el archivo de localización para 'xx'
   ```
   → Corrige los archivos JSON faltantes

### Verificación de Pruebas

```bash
# 1. Compilar
xcodebuild -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# 2. Unit tests
xcodebuild test -scheme Asocia -only-testing:AsociaTests/LocalizationManagerTests

# 3. UI tests
xcodebuild test -scheme Asocia -only-testing:AsociaUITests/LocalizationManagerUITests

# Resultado esperado:
# ✅ 19 unit tests passed
# ✅ 20 UI tests passed
# ✅ Total: 39 tests passed
```

---

## 📊 Estado del Sistema

### Completado ✅
- ✅ LocalizationManager implementado y funcional
- ✅ 5 idiomas soportados (es, ca, gl, eu, en)
- ✅ Sistema observable con actualización en tiempo real
- ✅ Persistencia en UserDefaults
- ✅ Fallback a español automático
- ✅ Soporte de pluralización
- ✅ 19 pruebas unitarias (Swift Testing)
- ✅ 20 pruebas de UI (XCTest)
- ✅ Integración con AsociaApp
- ✅ Soporte para UI testing con argumentos de lanzamiento

### Pendiente de Verificar ⚠️
- ⚠️ Archivos JSON completos con todas las traducciones
- ⚠️ Cobertura de código al 100%
- ⚠️ Selector de idioma en SettingsView (opcional)

---

## 📚 Referencias

### Documentación de Apple
- [Swift Testing](https://developer.apple.com/documentation/testing)
- [XCTest UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Localization Best Practices](https://developer.apple.com/documentation/xcode/localization)
- [Observable Macro](https://developer.apple.com/documentation/observation)

### Estándares
- [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- [JSON Validator](https://jsonlint.com)

### Testing Frameworks
- Swift Testing: Nuevo framework de Apple con macros `@Test` y `@Suite`
- XCTest: Framework clásico para unit tests e integración
- XCTest UI Testing: Para automatización de UI

---

## 🆘 Obtener Ayuda

Si encuentras problemas:

1. **Revisa esta guía** - Especialmente la sección de solución de problemas
2. **Lee los logs** - La consola de Xcode tiene información valiosa
3. **Ejecuta las pruebas** - Te dirán qué está fallando exactamente
4. **Limpia el proyecto** - A veces derived data causa problemas
5. **Reinicia Xcode** - El clásico "turn it off and on again"

### Comandos de Diagnóstico

```bash
# Ver contenido del bundle
xcodebuild -showBuildSettings -scheme Asocia | grep CONTENTS_FOLDER_PATH

# Verificar archivos en el bundle (después de compilar)
ls -la ~/Library/Developer/Xcode/DerivedData/Asocia-*/Build/Products/Debug-iphonesimulator/Asocia.app/

# Limpiar todo y empezar de cero
xcodebuild clean -scheme Asocia
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*
```

---

## 📝 Notas Finales

### Sobre las Pruebas Unitarias
- Usan Swift Testing (moderno, con macros)
- Todas limpian UserDefaults después de ejecutarse
- `setLanguage()` es asíncrono, usa `await`

### Sobre las Pruebas de UI
- Usan XCTest (framework recomendado por Apple para UI)
- Verifican que identificadores de accesibilidad sean consistentes
- Usan predicados NSPredicate para buscar textos dinámicos

### Sobre los Archivos JSON
- Deben estar en formato UTF-8
- Las claves usan dot-notation (ej: `app.name`, `common.accept`)
- Soportan variables con `%d` para números, `%@` para strings

---

**Guía creada:** 27 de julio de 2026  
**Última actualización:** 27 de julio de 2026  
**Versión:** 2.0 (Unificada)

✨ **¡Sistema de localización completo y testeado!**

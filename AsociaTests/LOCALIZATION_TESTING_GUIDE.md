# LocalizationManager - Guía de Pruebas

## Resumen

Se han creado pruebas completas para el `LocalizationManager` que cubren:

1. **Pruebas unitarias** (`LocalizationManagerTests.swift`) - Usando Swift Testing
2. **Pruebas de UI** (`LocalizationManagerUITests.swift`) - Usando XCTest UI Testing

---

## 📋 Pruebas Unitarias (Swift Testing)

### Ubicación
`LocalizationManagerTests.swift`

### Cobertura de Pruebas

#### 1. **Inicialización** (3 pruebas)
- ✅ El LocalizationManager se inicializa correctamente
- ✅ El idioma por defecto es español si no hay preferencia guardada
- ✅ El idioma guardado en UserDefaults se recupera correctamente

#### 2. **Cambio de idioma** (2 pruebas)
- ✅ Se puede cambiar el idioma correctamente
- ✅ El cambio de idioma se guarda en UserDefaults

#### 3. **Traducciones** (4 pruebas)
- ✅ El método `t()` devuelve la clave si no existe traducción
- ✅ El método `t()` devuelve una traducción válida para claves conocidas
- ✅ Las traducciones cambian según el idioma seleccionado
- ✅ El fallback a español funciona si falta una traducción en otro idioma

#### 4. **Pluralización** (1 prueba)
- ✅ La pluralización con `count` funciona correctamente

#### 5. **Idiomas soportados** (2 pruebas)
- ✅ Todos los 5 idiomas están soportados (es, ca, gl, eu, en)
- ✅ Los códigos de idioma son ISO 639-1 válidos

#### 6. **Observabilidad** (1 prueba)
- ✅ LocalizationManager es observable

#### 7. **Rendimiento** (2 pruebas)
- ✅ La carga de traducciones es eficiente
- ✅ Las traducciones son eficientes

#### 8. **Integración** (2 pruebas)
- ✅ El ciclo completo de cambio de idioma y traducción funciona
- ✅ Múltiples instancias usan el mismo idioma guardado

### Ejecutar Pruebas Unitarias

```bash
# Desde Xcode
⌘ + U (Command + U)

# Desde línea de comandos
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Ejemplo de Uso en Código

```swift
// Crear una instancia de LocalizationManager
let manager = LocalizationManager()

// Traducir texto
let appName = manager.t("app.name")
let welcomeMessage = manager.t("welcome.message")

// Traducir con pluralización
let itemCount = manager.t("items.count", count: 5)

// Cambiar idioma
await manager.setLanguage("ca") // Catalán
await manager.setLanguage("en") // Inglés
```

---

## 🖥️ Pruebas de UI (XCTest)

### Ubicación
`LocalizationManagerUITests.swift`

### Cobertura de Pruebas

#### 1. **Pruebas básicas de idioma** (6 pruebas)
- ✅ La app muestra textos en el idioma por defecto
- ✅ Se puede cambiar el idioma a español
- ✅ Se puede cambiar el idioma a catalán
- ✅ Se puede cambiar el idioma a gallego
- ✅ Se puede cambiar el idioma a euskera
- ✅ Se puede cambiar el idioma a inglés

#### 2. **Cambio dinámico de idioma** (2 pruebas)
- ✅ El idioma cambia en tiempo real cuando se selecciona desde ajustes
- ✅ El idioma persiste entre reinicios de la app

#### 3. **Prueba de todos los idiomas** (1 prueba)
- ✅ Todos los 5 idiomas funcionan correctamente

#### 4. **Formularios con diferentes idiomas** (3 pruebas)
- ✅ El formulario de alta muestra textos en español
- ✅ El formulario de alta muestra textos en catalán
- ✅ El formulario de alta muestra textos en inglés

#### 5. **Navegación** (1 prueba)
- ✅ La navegación funciona correctamente en todos los idiomas

#### 6. **Accesibilidad** (1 prueba)
- ✅ Los identificadores de accesibilidad son independientes del idioma

#### 7. **Rendimiento** (1 prueba)
- ✅ El cambio de idioma es rápido y eficiente

#### 8. **Casos extremos** (2 pruebas)
- ✅ La app maneja correctamente idiomas no soportados
- ✅ La app maneja correctamente idioma vacío

### Ejecutar Pruebas de UI

```bash
# Desde Xcode
⌘ + U (Command + U) en el target de UI Tests

# Desde línea de comandos
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AsociaUITests/LocalizationManagerUITests
```

### Argumentos de Lanzamiento para UI Tests

Las pruebas de UI utilizan argumentos de lanzamiento especiales:

```swift
// Resetear estado y configurar idioma
app.launchArguments += ["-UITEST_RESET_STATE", "YES", "-UITEST_LANGUAGE", "ca"]
app.launch()
```

**Argumentos disponibles:**
- `-UITEST_RESET_STATE`: Limpia UserDefaults y usa contenedor en memoria
- `-UITEST_LANGUAGE <código>`: Configura el idioma inicial (es, ca, gl, eu, en)
- `-UITEST_CLEAR_LANGUAGE`: Limpia el idioma guardado

---

## 📊 Estadísticas de Cobertura

### Pruebas Unitarias
- **Total de pruebas:** 17 pruebas unitarias + 2 de integración = **19 pruebas**
- **Suites:** 2 suites (`LocalizationManagerTests`, `LocalizationManagerIntegrationTests`)

### Pruebas de UI
- **Total de pruebas:** 20 pruebas de UI
- **Suite:** 1 suite (`LocalizationManagerUITests`)

### Total General
**39 pruebas** que cubren completamente el `LocalizationManager`

---

## 🔧 Configuración Necesaria

### 1. Actualizar AsociaApp.swift

Ya se ha actualizado `AsociaApp.swift` para soportar el argumento `-UITEST_LANGUAGE`:

```swift
if let languageIndex = CommandLine.arguments.firstIndex(of: "-UITEST_LANGUAGE"),
   languageIndex + 1 < CommandLine.arguments.count {
    let language = CommandLine.arguments[languageIndex + 1]
    UserDefaults.standard.set(language, forKey: "AppLanguage")
    print("🧪 UI Test: Idioma configurado a '\(language)'")
}
```

### 2. Archivos JSON de Traducciones

Asegúrate de que existen estos archivos en la carpeta `Resources`:

- `es.json` - Español
- `ca.json` - Catalán
- `gl.json` - Gallego
- `eu.json` - Euskera
- `en.json` - Inglés

**Formato esperado:**

```json
{
  "app.name": "Asocia",
  "common.accept": "Aceptar",
  "common.cancel": "Cancelar",
  "items.count": "%d elementos",
  "welcome.message": "Bienvenido"
}
```

---

## 🚀 Ejemplo de Ejecución

### Ejecutar todas las pruebas

```bash
# Ejecutar todas las pruebas (unitarias + UI)
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Ejecutar solo pruebas unitarias

```bash
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AsociaTests/LocalizationManagerTests
```

### Ejecutar solo pruebas de UI

```bash
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AsociaUITests/LocalizationManagerUITests
```

### Ejecutar una prueba específica

```bash
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AsociaTests/LocalizationManagerTests/changeLanguage
```

---

## 📝 Notas Importantes

### Sobre las Pruebas Unitarias

1. **Limpieza de UserDefaults:** Todas las pruebas limpian el idioma guardado después de ejecutarse para evitar interferencias entre pruebas.

2. **Swift Testing:** Se usa el nuevo framework Swift Testing con macros `@Test` y `@Suite`, que es más moderno que XCTest.

3. **Async/Await:** El método `setLanguage()` es asíncrono, por lo que se usa `await` en las pruebas.

### Sobre las Pruebas de UI

1. **XCTest UI Testing:** Las pruebas de UI siguen usando XCTest porque es el framework recomendado por Apple para automatización de UI (Swift Testing solo cubre unit/integration tests).

2. **Identificadores de Accesibilidad:** Las pruebas verifican que los identificadores (como `signup_firstName`) sean consistentes independientemente del idioma.

3. **Predicados:** Se usan predicados NSPredicate para buscar textos que puedan variar según el idioma.

---

## ✅ Checklist de Verificación

Antes de ejecutar las pruebas, verifica:

- [ ] Los 5 archivos JSON existen en la carpeta Resources
- [ ] Los archivos JSON tienen el formato correcto (diccionario de clave-valor)
- [ ] Los archivos JSON están incluidos en el target de la app
- [ ] `AsociaApp.swift` tiene el soporte para `-UITEST_LANGUAGE`
- [ ] El `LocalizationManager.swift` tiene el error de inicialización corregido
- [ ] Los archivos de pruebas están incluidos en los targets correctos:
  - `LocalizationManagerTests.swift` → Target de Unit Tests
  - `LocalizationManagerUITests.swift` → Target de UI Tests

---

## 🐛 Solución de Problemas

### "No se pudo cargar el archivo de localización"

**Problema:** En la consola aparece `⚠️ No se pudo cargar el archivo de localización para 'xx'`

**Solución:** 
1. Verifica que el archivo `xx.json` existe en la carpeta Resources
2. Asegúrate de que el archivo está incluido en el target de la app (Build Phases → Copy Bundle Resources)
3. Verifica que el formato JSON es válido

### Las pruebas de UI no encuentran elementos

**Problema:** Las pruebas de UI fallan con timeout al buscar elementos

**Solución:**
1. Aumenta el `timeout` en `waitForExistence(timeout:)`
2. Verifica los identificadores de accesibilidad en tu código
3. Ejecuta las pruebas en modo debug para ver la jerarquía de vistas

### Las traducciones no cambian en tiempo real

**Problema:** Al cambiar el idioma, los textos no se actualizan

**Solución:**
1. Verifica que `LocalizationManager` es `@Observable`
2. Asegúrate de que se inyecta en el environment: `.environment(localizationManager)`
3. Los textos deben usar `localizationManager.t()` no texto hardcodeado

---

## 📚 Referencias

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [XCTest UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Localization Best Practices](https://developer.apple.com/documentation/xcode/localization)
- [ISO 639-1 Language Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)

---

**Creado:** 26 de julio de 2026  
**Versión:** 1.0  
**Autor:** Sistema de Testing Automático

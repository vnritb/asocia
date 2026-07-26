# ✅ Checklist de Verificación - LocalizationManager

## Estado Actual de la Migración

Has movido correctamente:
- ✅ `LocalizationManager.swift` → `App/LocalizationManager-App.swift`
- ✅ `LocalizationManagerTests.swift` → `AsociaTests/`
- ✅ `LocalizationManagerUITests.swift` → `AsociaUITests/`

---

## 🔍 Verificaciones Completadas

### 1. ✅ Imports Corregidos

**LocalizationManagerTests.swift**
```swift
// ❌ NO usar: import Testing (ya está disponible implícitamente)
import Foundation
@testable import Asocia
```

**LocalizationManagerUITests.swift**
```swift
// ❌ NO usar: import XCTest (ya está disponible implícitamente)
// Solo necesitas el comentario de documentación y la clase
```

**IMPORTANTE:** Este proyecto NO requiere `import Testing` ni `import XCTest` explícitamente. Los frameworks ya están disponibles en los targets correspondientes.

### 2. ✅ AsociaApp.swift Actualizado

- Soporte para `-UITEST_LANGUAGE` agregado
- Configuración de idioma en modo UI Testing funcional

---

## 📋 Checklist de Configuración del Proyecto

### Archivos de Código

- [x] **LocalizationManager-App.swift** está en la carpeta `App/`
- [x] **LocalizationManagerTests.swift** está en `AsociaTests/`
- [x] **LocalizationManagerUITests.swift** está en `AsociaUITests/`
- [x] Los imports están correctos (Testing, XCTest)
- [x] AsociaApp.swift usa `LocalizationManager()`

### Archivos JSON de Traducciones

Verifica que estos archivos existen en **Resources/** y están incluidos en el target de la app:

- [ ] `Resources/es.json` - Español
- [ ] `Resources/ca.json` - Catalán
- [ ] `Resources/gl.json` - Gallego
- [ ] `Resources/eu.json` - Euskera
- [ ] `Resources/en.json` - Inglés

**Cómo verificar en Xcode:**
1. Selecciona cada archivo JSON en el navegador
2. En el Inspector de Archivos (panel derecho), verifica que esté marcado el checkbox del target principal
3. Verifica que aparecen en Build Phases → Copy Bundle Resources

### Formato de los JSON

Cada archivo debe tener este formato:

```json
{
  "app.name": "Asocia",
  "common.accept": "Aceptar",
  "common.cancel": "Cancelar",
  "common.yes": "Sí",
  "common.no": "No",
  "welcome.message": "Bienvenido a Asocia",
  "items.count": "%d elementos"
}
```

---

## 🧪 Verificación de Targets

### Target Principal (Asocia)

Debe incluir:
- [x] `LocalizationManager-App.swift`
- [ ] `es.json`
- [ ] `ca.json`
- [ ] `gl.json`
- [ ] `eu.json`
- [ ] `en.json`

### Target de Unit Tests (AsociaTests)

Debe incluir:
- [x] `LocalizationManagerTests.swift`
- [x] `WorldLanguagesTests.swift`
- [x] Otros archivos de tests unitarios

**Verificar que tiene:**
- Host Application: Asocia
- @testable import Asocia funciona

### Target de UI Tests (AsociaUITests)

Debe incluir:
- [x] `LocalizationManagerUITests.swift`
- [x] `AsociaUITests.swift`

**Verificar que tiene:**
- Target Application: Asocia

---

## 🚀 Pruebas de Funcionamiento

### 1. Compilar el Proyecto

```bash
# Desde Xcode: ⌘ + B (Command + B)
# O desde terminal:
xcodebuild -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

**Resultado esperado:** Compilación exitosa sin errores

### 2. Ejecutar Pruebas Unitarias

```bash
# Desde Xcode: ⌘ + U (Command + U)
# O una prueba específica: ⌘ + Control + Opción + U

# Desde terminal:
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AsociaTests/LocalizationManagerTests
```

**Resultado esperado:** 19 pruebas pasan

### 3. Ejecutar Pruebas de UI

```bash
# Desde terminal:
xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AsociaUITests/LocalizationManagerUITests
```

**Resultado esperado:** 20 pruebas pasan

### 4. Ejecutar la App

1. Ejecuta la app en el simulador
2. Verifica que aparece el log en consola:
   ```
   ✅ Localizaciones cargadas: ca, en, es, eu, gl
   ```
3. Si aparece warnings como `⚠️ No se pudo cargar...`, revisa que los JSON estén en el bundle

---

## 🐛 Solución de Problemas Comunes

### Error: "Unable to find module dependency: 'Testing'" o "Unable to find module dependency: 'XCTest'"

**Problema:** Los archivos tienen imports explícitos que no son necesarios

**Solución:**
1. **ELIMINA** `import Testing` de los archivos de unit tests
2. **ELIMINA** `import XCTest` de los archivos de UI tests
3. Los frameworks ya están disponibles implícitamente en este proyecto
4. Solo necesitas `import Foundation` y `@testable import Asocia` en unit tests

**Ejemplo correcto para unit tests:**
```swift
import Foundation
@testable import Asocia

@Suite("Mi Test Suite")
struct MiTest {
    @Test func miPrueba() {
        #expect(true)
    }
}
```

**Ejemplo correcto para UI tests:**
```swift
@MainActor
final class MiUITest: XCTestCase {
    func testAlgo() {
        XCTAssertTrue(true)
    }
}
```

### Error: "No such module 'Testing'"

**Problema:** El target de tests no tiene acceso al framework Testing

**Solución:**
1. ~~Selecciona el target AsociaTests~~ ← NO NECESARIO en este proyecto
2. ~~Build Phases → Link Binary With Libraries~~ ← NO NECESARIO
3. ~~Agrega `Testing.framework`~~ ← NO NECESARIO
4. **SOLUCIÓN REAL:** Elimina `import Testing` del archivo - ya está disponible implícitamente

### Error: "Cannot find 'LocalizationManager' in scope"

**Problema:** El target de tests no puede importar Asocia

**Solución:**
1. Verifica que `LocalizationManager-App.swift` está en el target principal (Asocia)
2. Verifica que la clase no sea `private`
3. Asegúrate de tener `@testable import Asocia` en el archivo de tests

### Error: "No such file 'es.json'"

**Problema:** Los archivos JSON no están en el bundle

**Solución:**
1. Selecciona cada archivo JSON en Xcode
2. En File Inspector, marca el checkbox del target Asocia
3. Verifica en Build Phases → Copy Bundle Resources que aparecen los 5 JSON

### Las pruebas de UI fallan con timeout

**Problema:** Los elementos no se encuentran en la UI

**Solución:**
1. Ejecuta las pruebas en modo debug para ver la jerarquía
2. Aumenta el timeout si la app tarda en cargar
3. Verifica que los identificadores de accesibilidad estén configurados

### Warning: "No se pudo cargar el archivo de localización"

**Problema:** Un archivo JSON no se encuentra o tiene formato incorrecto

**Solución:**
1. Verifica que el archivo existe en Resources/
2. Valida el JSON en un validador (jsonlint.com)
3. Asegúrate de que el nombre coincide exactamente (minúsculas, .json)

---

## 📝 Ejemplo de Estructura del Proyecto

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
│   ├── LocalizationManagerTests.swift ✅
│   ├── WorldLanguagesTests.swift ✅
│   └── ... otros tests
└── AsociaUITests/
    ├── LocalizationManagerUITests.swift ✅
    ├── AsociaUITests.swift ✅
    └── ... otros UI tests
```

---

## 🎯 Próximos Pasos

1. **Verificar archivos JSON**
   - Confirma que los 5 archivos existen
   - Verifica que están incluidos en el target
   - Valida que tienen el formato correcto

2. **Ejecutar todas las pruebas**
   ```bash
   xcodebuild test -scheme Asocia -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
   ```

3. **Ejecutar la app y verificar logs**
   - Busca el mensaje: `✅ Localizaciones cargadas: ca, en, es, eu, gl`
   - Si hay warnings, corrige los archivos JSON faltantes

4. **Probar el cambio de idioma**
   - Si tienes un selector de idioma en Settings, pruébalo manualmente
   - Verifica que los textos cambian en tiempo real

---

## ✨ Comandos Útiles

### Limpiar build y derivedData
```bash
xcodebuild clean -scheme Asocia
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*
```

### Ejecutar solo tests de LocalizationManager
```bash
# Unit tests
xcodebuild test -scheme Asocia -only-testing:AsociaTests/LocalizationManagerTests

# UI tests
xcodebuild test -scheme Asocia -only-testing:AsociaUITests/LocalizationManagerUITests

# Ambos
xcodebuild test -scheme Asocia \
  -only-testing:AsociaTests/LocalizationManagerTests \
  -only-testing:AsociaUITests/LocalizationManagerUITests
```

### Ver cobertura de código
```bash
xcodebuild test -scheme Asocia -enableCodeCoverage YES
```

---

## 📊 Estado Final

- ✅ Código corregido y movido
- ✅ Imports agregados
- ✅ AsociaApp.swift actualizado
- ⚠️ Pendiente verificar archivos JSON en Resources
- ⚠️ Pendiente ejecutar pruebas para confirmar

**Próximo paso:** Verifica que los archivos JSON existen y están incluidos en el target, luego ejecuta las pruebas.

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0

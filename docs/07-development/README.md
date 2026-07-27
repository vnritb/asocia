# 🛠️ Desarrollo - Asocia

Herramientas y utilidades para desarrollo.

---

## 📄 Documentos en esta Sección

### [SAMPLE_DATA_GUIDE.md](./SAMPLE_DATA_GUIDE.md)
**Guía de Datos de Prueba**

Cómo cargar y gestionar datos de prueba:
- 📊 Crear datos de ejemplo
- 🧪 Datos para testing
- 👤 Usuarios de prueba
- 🔄 Resetear datos
- 💾 PersistenceController

### [CLEAN_RESET_GUIDE.md](./CLEAN_RESET_GUIDE.md)
**Guía de Limpieza y Reseteo**

Cómo limpiar el proyecto completamente:
- 🗑️ Limpiar derived data
- 📦 Limpiar build
- 💾 Resetear SwiftData
- 🔑 Limpiar Keychain
- 📱 Resetear simulador

### [SERVICE_LOGGING_GUIDE.md](./SERVICE_LOGGING_GUIDE.md)
**Guía de Logging de Servicios**

Sistema de logging para debugging:
- 📝 Logging en servicios
- 🔍 Filtrar logs
- 📊 Ver peticiones HTTP
- ⏱️ Medir tiempos de respuesta
- 🎨 Logs visuales con emojis

### [LOGGING_ADDED_SUMMARY.md](./LOGGING_ADDED_SUMMARY.md)
**Resumen de Logging Agregado**

Resumen de logging implementado:
- ✅ Logging en APIClient
- ✅ Logging en AuthService
- 📡 Peticiones HTTP detalladas
- 🧪 Ejemplos de consola
- 🔧 Debugging avanzado

---

## 🎯 Flujos Comunes

### 1. Empezar con Datos Limpios

```bash
# 1. Limpiar proyecto
xcodebuild clean -scheme Asocia
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*

# 2. Resetear simulador
xcrun simctl shutdown all
xcrun simctl erase all

# 3. Ejecutar app
# SwiftData cargará datos de prueba automáticamente
```

### 2. Ver Logs Detallados

```bash
# 1. Ejecutar app: ⌘ + R
# 2. Abrir consola: ⌘ + Shift + Y
# 3. Filtrar por:
#    - 📡 para ver peticiones API
#    - 🔐 para ver autenticación
#    - ✅ para ver éxitos
#    - ❌ para ver errores
```

### 3. Resetear Solo SwiftData

```swift
// En código temporal
#if DEBUG
let url = URL.applicationSupportDirectory.appending(path: "default.store")
try? FileManager.default.removeItem(at: url)
#endif
```

### 4. Cargar Datos de Prueba Manualmente

```swift
// En PersistenceController.swift
#if DEBUG
PersistenceController.loadSampleDataIfNeeded()
#endif
```

---

## 🧪 Datos de Prueba

### Usuario de Ejemplo

```swift
let member = Member(
    firstName: "Ana",
    firstSurname: "García",
    email: "ana.garcia@example.com",
    mobilePhone: "600123456",
    membershipStatus: .active
)
```

### Cargar en SwiftData

```swift
let context = modelContainer.mainContext
context.insert(member)
try context.save()
```

---

## 📝 Logging

### Ejemplo de Consola

```
📡 [API] fetchCurrentMember
   🌐 [GET] http://localhost:3000/v1/members/me
   🔐 Authenticated: Yes (token presente)
   ✅ Response: 200 (156ms)
   ✅ Member fetched - Status: active

🔐 [AUTH] login - email: test@test.com
   🌐 [POST] http://localhost:4001/v1/auth/login
   ✅ Response: 201 (387ms)
   ✅ Login exitoso - Token guardado
```

### Tipos de Logs

- **📡** - Peticiones API
- **🔐** - Autenticación
- **🌐** - HTTP requests
- **✅** - Éxito
- **❌** - Error
- **⚠️** - Warning
- **🧪** - Testing/Mock

---

## 🔧 Comandos Útiles

### Limpiar Todo

```bash
# Limpiar build
xcodebuild clean -scheme Asocia

# Limpiar derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*

# Limpiar simuladores
xcrun simctl shutdown all
xcrun simctl erase all

# Reiniciar Xcode
killall Xcode
```

### Ver Logs en Tiempo Real

```bash
# Logs del simulador
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Asocia"'

# O en Xcode:
# View → Debug Area → Activate Console
# ⌘ + Shift + Y
```

### Verificar SwiftData

```bash
# Ubicación de la base de datos
~/Library/Developer/CoreSimulator/Devices/<UUID>/data/Containers/Data/Application/<UUID>/Library/Application Support/

# Buscar archivo .store
find ~/Library/Developer/CoreSimulator -name "*.store"
```

---

## 🐛 Debugging

### Problem: App se congela

1. Abrir consola (⌘ + Shift + Y)
2. Buscar warnings o errores
3. Verificar que el backend responde:
   ```bash
   curl http://localhost:4001/health
   curl http://localhost:3000/health
   ```

### Problem: Datos no se guardan

1. Verificar logs de SwiftData:
   ```
   💾 Datos de prueba guardados en SwiftData
   ```
2. Verificar ModelContext:
   ```swift
   try context.save()
   ```

### Problem: Logs no aparecen

1. Verificar que estás en modo Debug (no Release)
2. Los logs están dentro de `#if DEBUG`
3. Limpiar build: `⌘ + Shift + K`

---

## 🎨 Mejores Prácticas

### 1. Usar Logging

```swift
#if DEBUG
print("📡 [API] fetchData - \(id)")
#endif
```

### 2. Cargar Datos de Prueba

```swift
#if DEBUG
if !isUITesting {
    PersistenceController.loadSampleDataIfNeeded()
}
#endif
```

### 3. Limpiar en Tests

```swift
override func setUp() {
    UserDefaults.standard.removePersistentDomain(
        forName: Bundle.main.bundleIdentifier!
    )
}
```

---

## 🔗 Enlaces Relacionados

- **Testing**: [docs/06-localization/](../06-localization/) (39 tests)
- **Backend**: [docs/04-backend/](../04-backend/)
- **Arquitectura**: [docs/02-architecture/](../02-architecture/)

---

**Última actualización:** 27 de julio de 2026

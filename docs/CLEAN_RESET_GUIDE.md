# 🔄 Cómo Ejecutar la App Limpia (Como Primera Vez)

## 🎯 Objetivo

Eliminar todos los datos persistentes para simular una instalación nueva de la app.

---

## 🚀 Método 1: Borrar App y Datos del Simulador (Recomendado)

### Desde Xcode

1. **Para la app** si está ejecutándose: `⌘ + .`
2. **Borrar la app del simulador**:
   - En el simulador, mantén presionado el ícono de Asocia
   - Tap en "Remove App"
   - Confirma "Delete App"
3. **Ejecuta de nuevo**: `⌘ + R`

### Desde el Menú del Simulador

1. **Device → Erase All Content and Settings...**
2. Confirma "Erase"
3. Espera a que el simulador se reinicie
4. **Ejecuta la app**: `⌘ + R`

⚠️ **Advertencia:** Esto borra TODAS las apps y datos del simulador, no solo tu app.

---

## 🛠️ Método 2: Limpiar Build y Derived Data (Más Completo)

### Paso 1: Limpiar Build

```bash
# En Xcode
⌘ + Shift + K
```

O desde terminal:
```bash
xcodebuild clean -scheme Asocia
```

### Paso 2: Borrar Derived Data

**Opción A: Desde Xcode**
```
1. Xcode → Settings (⌘ + ,)
2. Locations tab
3. Click en la flecha junto a "Derived Data"
4. Se abre Finder con la carpeta DerivedData
5. Busca la carpeta "Asocia-..." y bórrala
6. Cierra Xcode
7. Abre Xcode de nuevo
```

**Opción B: Desde Terminal**
```bash
# Borrar Derived Data de tu proyecto
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*

# O borrar TODO el Derived Data (más lento de reconstruir)
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Paso 3: Borrar App del Simulador

```bash
# Desde terminal
xcrun simctl uninstall booted com.tu.bundle.id.Asocia
```

O manualmente desde el simulador (método 1).

### Paso 4: Rebuild

```bash
⌘ + Shift + K  # Limpiar
⌘ + B          # Compilar
⌘ + R          # Ejecutar
```

---

## 🔧 Método 3: Resetear Solo los Datos de la App

### Usando el Simulador

1. **Simulador → Device → Erase All Content and Settings**
2. O borra solo tu app: mantén presionado el ícono → "Remove App"

### Usando xcrun (Terminal)

```bash
# Listar simuladores disponibles
xcrun simctl list devices

# Resetear un simulador específico
xcrun simctl erase "iPhone 15 Pro"

# Borrar solo tu app del simulador activo
xcrun simctl uninstall booted com.tu.bundle.id.Asocia

# Borrar datos de la app (sin desinstalarla)
xcrun simctl privacy booted reset all com.tu.bundle.id.Asocia
```

---

## 🧹 Método 4: Script de Limpieza Completa

### Crear un Script

Crea un archivo `clean_reset.sh` en la raíz del proyecto:

```bash
#!/bin/bash

echo "🧹 Limpiando proyecto Asocia..."

# 1. Limpiar build
echo "1️⃣ Limpiando build..."
xcodebuild clean -scheme Asocia

# 2. Borrar Derived Data
echo "2️⃣ Borrando Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Asocia-*

# 3. Borrar app del simulador
echo "3️⃣ Borrando app del simulador..."
xcrun simctl uninstall booted com.yourcompany.Asocia 2>/dev/null || true

# 4. Resetear permisos y datos
echo "4️⃣ Reseteando permisos..."
xcrun simctl privacy booted reset all com.yourcompany.Asocia 2>/dev/null || true

echo "✅ Limpieza completa!"
echo "Ahora ejecuta la app con ⌘ + R"
```

### Dar Permisos y Ejecutar

```bash
chmod +x clean_reset.sh
./clean_reset.sh
```

---

## 🎯 Método 5: Usando Launch Arguments (Para Testing)

Ya tienes esto implementado en tu app. Cuando ejecutas UI tests con:

```swift
app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
```

Esto limpia:
- ✅ UserDefaults
- ✅ Usa contenedor en memoria (no persistente)

### Para Uso Manual

Puedes agregar un **scheme** con este argument:

1. **Product → Scheme → Edit Scheme** (⌘ + <)
2. **Run → Arguments**
3. En "Arguments Passed On Launch" agrega:
   ```
   -UITEST_RESET_STATE YES
   ```
4. **Close**
5. Ahora cuando ejecutes `⌘ + R`, la app se iniciará limpia

---

## 📊 Método 6: Borrar Datos Específicos

### UserDefaults

Si solo quieres borrar las preferencias:

```swift
// Agregar temporalmente en AsociaApp.swift init()
#if DEBUG
if CommandLine.arguments.contains("-RESET_USERDEFAULTS") {
    UserDefaults.standard.removePersistentDomain(
        forName: Bundle.main.bundleIdentifier!
    )
    print("🗑️ UserDefaults borrados")
}
#endif
```

### Keychain (Token de Auth)

Agregar en `AsociaApp.swift`:

```swift
#if DEBUG
if CommandLine.arguments.contains("-RESET_KEYCHAIN") {
    KeychainStore.deleteToken()
    print("🗑️ Keychain limpio")
}
#endif
```

### SwiftData (Base de Datos)

Ya tienes esto con `-UITEST_RESET_STATE`, pero puedes crear uno específico:

```swift
#if DEBUG
if CommandLine.arguments.contains("-RESET_DATABASE") {
    self.modelContainer = PersistenceController.inMemoryContainer()
    print("🗑️ Usando base de datos en memoria")
}
#endif
```

---

## 🎮 Método 7: Crear Schemes para Diferentes Estados

### Scheme: "Asocia (Fresh Install)"

1. **Product → Scheme → Manage Schemes**
2. **Duplica el scheme "Asocia"**
3. **Renombra** a "Asocia (Fresh Install)"
4. **Edit Scheme** → Run → Arguments
5. Agrega:
   ```
   -UITEST_RESET_STATE YES
   -RESET_USERDEFAULTS YES
   -RESET_KEYCHAIN YES
   ```
6. **Close**

Ahora puedes elegir el scheme antes de ejecutar:
```
Scheme dropdown (junto a ⏵ Run) → "Asocia (Fresh Install)" → ⌘ + R
```

---

## ✅ Checklist: ¿Qué Necesitas Limpiar?

Para una instalación completamente nueva:

- [ ] **App del simulador** - Desinstalar
- [ ] **UserDefaults** - Borrar preferencias (idioma, etc.)
- [ ] **Keychain** - Borrar token de autenticación
- [ ] **SwiftData** - Borrar base de datos local
- [ ] **Derived Data** - Limpiar builds antiguos
- [ ] **Build** - Limpiar compilación

---

## 🚀 Método Rápido (Día a Día)

### Para Testing Rápido

```bash
# 1. Para la app
⌘ + .

# 2. En el simulador, borra la app (mantén presionado el ícono)

# 3. Ejecuta de nuevo
⌘ + R
```

**Tiempo:** ~10 segundos

### Para Limpieza Completa

```bash
# 1. Limpiar build
⌘ + Shift + K

# 2. Borrar app del simulador (manual)

# 3. Ejecutar
⌘ + R
```

**Tiempo:** ~30 segundos

### Para Problemas Graves

```bash
# 1. Cerrar Xcode
# 2. Borrar Derived Data (desde Finder)
# 3. Resetear simulador (Device → Erase All Content and Settings)
# 4. Abrir Xcode
# 5. Compilar y ejecutar
⌘ + B
⌘ + R
```

**Tiempo:** ~2-3 minutos

---

## 🔍 Verificar que Está Limpio

### Al Arrancar la App

Deberías ver en consola:

```
🚀 AsociaApp.task iniciado
✅ Localizaciones cargadas: ca, en, es, eu, gl
   SyncEngine inicializado

📡 [API] fetchCurrentMember
   🔐 Authenticated: No
   ❌ No auth token available
```

El `❌ No auth token available` confirma que no hay sesión previa.

### En la UI

- ✅ Deberías ver el botón "Asocia" (pantalla de bienvenida)
- ✅ NO deberías ver la pantalla de perfil
- ✅ NO deberías tener acceso al chat

---

## 🐛 Solución de Problemas

### "La app sigue mostrando datos antiguos"

**Causa:** UserDefaults o Keychain no se borraron

**Solución:**
1. Borra la app del simulador completamente
2. O usa `-UITEST_RESET_STATE YES` en launch arguments

### "El simulador no responde después de reset"

**Causa:** El simulador necesita reiniciarse

**Solución:**
```bash
# Apagar simulador
⌘ + Q (en el simulador)

# Desde terminal
xcrun simctl shutdown all
xcrun simctl erase all
```

### "Xcode muestra errores extraños"

**Causa:** Derived Data corrupto

**Solución:**
```bash
# Cerrar Xcode
# Borrar Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Abrir Xcode y rebuild
⌘ + Shift + K
⌘ + B
```

---

## 📋 Resumen: Métodos Ordenados por Velocidad

| Método | Tiempo | Qué Limpia | Cuándo Usar |
|--------|--------|------------|-------------|
| Borrar app del simulador | 10s | App + datos | Testing diario |
| Limpiar build | 15s | Compilación | Después de cambios grandes |
| Reset simulador | 30s | Todo el simulador | Problemas del simulador |
| Borrar Derived Data | 1-2min | Todos los builds | Errores extraños de Xcode |
| Script completo | 30s | Todo | Automatización |
| Scheme con arguments | 10s | Datos específicos | Testing frecuente |

---

## 🎯 Recomendación

**Para desarrollo diario:**
```
Borra la app del simulador → ⌘ + R
```

**Para testing sistemático:**
```
Crea un scheme "Fresh Install" con launch arguments
```

**Para problemas:**
```
Resetea el simulador completamente
```

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0

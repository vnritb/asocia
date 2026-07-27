# 🗑️ Guía para Limpiar la Base de Datos

## 🎯 Cuándo Usar Esta Guía

Usa esta guía cuando necesites:
- **Eliminar todos los datos de prueba** (como los 20 usuarios precargados)
- **Empezar desde cero** con la app
- **Resolver problemas** donde aparecen datos que no deberían estar
- **Probar el flujo de registro** desde un estado limpio

---

## 🧹 Método 1: Borrar el Archivo de la Base de Datos (RECOMENDADO)

Este es el método más simple y efectivo.

### En el Simulador

1. **Detener la app** si está corriendo (⌘ + .)

2. **En Terminal:**
   ```bash
   # Para iOS Simulator
   xcrun simctl get_app_container booted com.tu.bundle.id data
   
   # Esto te dará una ruta como:
   # /Users/tuusuario/Library/Developer/CoreSimulator/Devices/XXXXXX/data/Containers/Data/Application/XXXXXX
   ```

3. **Borrar el archivo de SwiftData:**
   ```bash
   rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Application\ Support/default.store*
   ```

4. **O más fácil: Borrar TODO y reinstalar**
   ```bash
   # Borrar la app del simulador
   xcrun simctl uninstall booted com.tu.bundle.id
   
   # Lanzar de nuevo desde Xcode (⌘ + R)
   ```

### En Dispositivo Físico

1. **Borrar la app** (mantén presionado el icono → Eliminar App)
2. **Reinstalar** desde Xcode (⌘ + R)

---

## 🧹 Método 2: Resetear el Simulador Completo

Si quieres empezar completamente limpio:

```bash
# Listar todos los simuladores
xcrun simctl list devices

# Borrar todo y resetear un simulador específico
xcrun simctl erase "iPhone 15 Pro"

# O borrar TODOS los simuladores
xcrun simctl erase all
```

⚠️ **Advertencia:** Esto borrará TODAS las apps y datos del simulador.

---

## 🧹 Método 3: Flag de Reset en el Código (Para Desarrollo)

Ya está implementado en el código actual. En `AsociaApp.swift`:

```swift
#if DEBUG
let url = URL.applicationSupportDirectory.appending(path: "default.store")
try? FileManager.default.removeItem(at: url)
#endif
```

Esto significa que en **modo Debug**, cada vez que compiles y corras la app, **la base de datos se borra automáticamente**.

---

## ✅ Verificar que Está Limpio

Después de hacer el reset:

1. **Lanzar la app** (⌘ + R)
2. **Ver la consola de Xcode**
3. Deberías ver:
   ```
   ✅ ModelContainer creado exitosamente
   ℹ️ loadSampleDataIfNeeded: Datos de prueba desactivados
   ```

4. **NO deberías ver:**
   ```
   📊 Creando 20 usuarios de prueba...
   ✅ Usuario 1/20: Ana García...
   ```

---

## 🔍 Verificar el Estado en la App

### Si NO has hecho signup:
- ✅ Deberías ver `LoginView` o `SignupView`
- ✅ NO deberías ver ningún usuario en el Chat

### Si haces signup con nombre "A":
- ✅ Deberías ver **TUS datos** (nombre, apellido, email que ingresaste)
- ✅ A los 8 segundos, tu estado cambia a `active`
- ✅ **NO deberías ver datos de Lucía ni ningún otro usuario de prueba**

---

## 🐛 Solución de Problemas

### Problema: "Todavía veo usuarios de prueba"

**Causa:** Los datos no se borraron correctamente.

**Solución:**
1. Desinstalar completamente la app del simulador
2. Borrar DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Clean Build Folder en Xcode (⇧ + ⌘ + K)
4. Rebuild (⇧ + ⌘ + B)
5. Run (⌘ + R)

### Problema: "Me aparecen datos de otro usuario después del signup"

**Causa posible 1:** Estás en modo Mock

**Solución:**
- Verificar que el scheme es **"Asocia (Local)"**, no "Asocia (Mock)"
- Product → Scheme → Asocia (Local)

**Causa posible 2:** El backend está devolviendo datos incorrectos

**Solución:**
- Verificar que el backend está limpio:
  ```bash
  cd backend
  docker compose down -v  # Borra los volúmenes
  docker compose up --build
  ```

### Problema: "La app crashea al iniciar después del reset"

**Causa:** Puede haber un problema con la migración de SwiftData.

**Solución:**
1. Borrar DerivedData
2. Clean Build Folder
3. Resetear el simulador completamente
4. Rebuild y run

---

## 📋 Checklist Post-Reset

Después de resetear, verifica:

- [ ] ✅ La app inicia correctamente
- [ ] ✅ NO hay usuarios de prueba en la base de datos
- [ ] ✅ El signup funciona correctamente
- [ ] ✅ Después del signup, ves TUS propios datos
- [ ] ✅ Si usaste nombre "A", se auto-valida en 8 segundos
- [ ] ✅ El estado cambia a `active` correctamente
- [ ] ✅ NO aparecen datos de Lucía u otros usuarios

---

## 🎯 Flujo Completo de Testing Limpio

Para probar desde cero:

```bash
# 1. Limpiar todo
rm -rf ~/Library/Developer/Xcode/DerivedData
xcrun simctl erase "iPhone 15 Pro"

# 2. Limpiar y rebuild
# En Xcode: ⇧ + ⌘ + K (Clean)
# Luego: ⌘ + B (Build)

# 3. Asegurarse que el backend esté limpio y corriendo
cd backend
docker compose down -v
docker compose up --build

# 4. Ejecutar la app
# En Xcode: ⌘ + R

# 5. Hacer signup con nombre "A"
# - Nombre: A
# - Apellido: TuApellido  
# - Email: tu@test.com
# - Password: 123456

# 6. Esperar 8 segundos

# 7. Verificar que ves TUS datos, no los de Lucía
```

---

**Fecha:** 27 de julio de 2026  
**Versión:** 1.0

¡La base de datos debería estar completamente limpia! 🎉

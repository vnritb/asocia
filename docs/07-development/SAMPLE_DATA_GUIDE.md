# 👥 Datos de Prueba Agregados

## ✅ Cambios Aplicados

He agregado funcionalidad para cargar **usuarios de prueba automáticamente** en la base de datos cuando ejecutes la app en modo desarrollo.

---

## 📊 Archivos Modificados

### 1. PersistenceController.swift

Agregué 3 nuevos métodos:

#### `previewContainer(withSampleData:)` 
Crea un contenedor con datos de prueba (útil para Previews)

#### `addSampleMembers(to:)` 
Agrega miembros de prueba a la base de datos

#### `loadSampleDataIfNeeded()`
Carga datos de prueba solo si la BD está vacía (solo en Debug)

### 2. AsociaApp.swift

Agregué llamada a `PersistenceController.loadSampleDataIfNeeded()` en el inicio de la app (solo en modo Debug, no en UI tests)

---

## 👤 Usuario de Prueba Incluido

### Ana García López
- **Email:** ana.garcia@example.com
- **Email 2:** ana@gmail.com
- **Móvil:** 600123456
- **Teléfono fijo:** 912345678
- **Dirección:** Calle Mayor 15, 3º B
- **Código Postal:** 28001
- **Ciudad:** Madrid
- **Provincia:** Madrid
- **Fecha de nacimiento:** 15/03/1995
- **Año de entrada:** 2013/2014
- **Año de salida:** 2018/2019
- **Promoción:** Promoción 2019
- **Profesión:** Ingeniera de Software
- **Lugar de trabajo:** Tech Solutions S.L.
- **IBAN:** ES9121000418450200051332
- **Redes sociales:**
  - Facebook: ana.garcia
  - Instagram: @anagarcia
  - X (Twitter): @ana_dev
- **Estado:** ✅ Activo
- **Fecha de alta:** Hace 1 año
- **Visible en búsqueda:** Sí
- **Estado de sync:** Sincronizado

---

## 🚀 Cómo Funciona

### Al Iniciar la App (Modo Debug)

1. **Si la BD está vacía** → Se carga automáticamente el usuario de prueba
2. **Si ya hay datos** → No hace nada (no sobreescribe)
3. **En UI tests** → No carga datos (para tests limpios)

### En la Consola Verás

```
🚀 AsociaApp.task iniciado
📊 No hay miembros en la BD. Cargando datos de prueba...
✅ Usuario de prueba agregado: Ana García López
💾 Datos de prueba guardados en SwiftData
   SyncEngine inicializado
```

O si ya hay datos:

```
🚀 AsociaApp.task iniciado
   SyncEngine inicializado
```

---

## 🎯 Cómo Usar

### Opción 1: Ejecutar la App Normalmente

```bash
⌘ + R
```

Si la BD está vacía, verás el perfil de Ana García.

### Opción 2: Forzar Carga de Datos

1. **Borra la app** del simulador
2. **Ejecuta de nuevo:** `⌘ + R`
3. **Verás el usuario de prueba** automáticamente

### Opción 3: Resetear y Cargar

```bash
# 1. Limpiar
⌘ + Shift + K

# 2. Borrar app del simulador (mantén presionado el ícono → Remove App)

# 3. Ejecutar
⌘ + R
```

---

## 🧪 Agregar Más Usuarios de Prueba

Si quieres agregar más usuarios, descomenta el código en `PersistenceController.swift`:

```swift
// En el método addSampleMembers(to:)
// Descomenta este bloque para agregar a Carlos:

let member2 = Member(
    firstName: "Carlos",
    firstSurname: "Rodríguez",
    secondSurname: "Martínez",
    email: "carlos@example.com",
    // ... resto de datos
    membershipStatus: .pendingApproval  // Usuario pendiente de aprobar
)
```

O agrega tu propio código:

```swift
let member3 = Member(
    firstName: "María",
    firstSurname: "González",
    secondSurname: "Sánchez",
    email: "maria@example.com",
    secondaryEmail: "",
    mobilePhone: "677888999",
    landlinePhone: "",
    address: "Plaza España 10",
    postalCode: "08001",
    city: "Barcelona",
    province: "Barcelona",
    birthDate: Calendar.current.date(from: DateComponents(year: 1992, month: 12, day: 5)),
    entryYear: "2010/2011",
    exitYear: "2015/2016",
    promotion: "Promoción 2016",
    profession: "Abogada",
    workplace: "Bufete Legal S.A.",
    iban: "",
    facebookUsername: "",
    instagramUsername: "@maria_lawyer",
    xUsername: "",
    tiktokUsername: "",
    photoData: nil,
    isSearchable: true,
    associationID: nil,
    isVisibleToOtherAssociations: false,
    membershipStatus: .active,
    joinDate: Date().addingTimeInterval(-730 * 24 * 60 * 60), // Hace 2 años
    rejectionReason: nil
)
member3.syncStatus = .synced
member3.serverUpdatedAt = Date()
context.insert(member3)
```

---

## 📱 Qué Verás en la App

### En la Pantalla de Perfil

- ✅ **Nombre completo:** Ana García López
- ✅ **Todos los datos** rellenados
- ✅ **Estado:** Activo
- ✅ **Sincronización:** Al día

### En Settings

- ✅ **No verás la sección Mock** (porque el usuario ya está activo)
- ✅ Puedes cambiar el idioma normalmente

### En Chat (si está implementado)

- ✅ Ana García aparecerá en búsquedas (porque `isSearchable = true`)

---

## 🔧 Personalización

### Cambiar los Datos del Usuario

Edita el método `addSampleMembers` en `PersistenceController.swift`:

```swift
let member1 = Member(
    firstName: "TuNombre",        // ← Cambia aquí
    firstSurname: "TuApellido",   // ← Y aquí
    // ... resto de datos
)
```

### Cambiar el Estado

```swift
membershipStatus: .pendingApproval  // Pendiente
membershipStatus: .active           // Activo
membershipStatus: .rejected         // Rechazado
```

### Agregar Foto

```swift
// En el futuro, puedes agregar:
photoData: UIImage(named: "samplePhoto")?.jpegData(compressionQuality: 0.8)
```

---

## 🐛 Solución de Problemas

### "No veo el usuario de prueba"

**Causa:** La BD ya tiene datos de antes

**Solución:**
1. Borra la app del simulador
2. Ejecuta de nuevo
3. O cambia el código para que siempre cargue:
   ```swift
   // En PersistenceController.swift
   // Quita la condición:
   if existingMembers.isEmpty {  // ← Borra esta línea
       addSampleMembers(to: context)
   }  // ← Y esta
   ```

### "Veo el usuario pero no puedo editarlo"

**Causa:** El syncStatus está en `synced`

**Solución:** Es normal. Puedes editarlo y el estado cambiará a `pendingUpload`

### "Quiero empezar sin datos"

**Solución:**
```swift
// En AsociaApp.swift, comenta esta línea:
// PersistenceController.loadSampleDataIfNeeded()
```

---

## ✅ Checklist de Verificación

- [x] `PersistenceController.swift` actualizado con métodos de datos de prueba
- [x] `AsociaApp.swift` llama a `loadSampleDataIfNeeded()`
- [x] Solo se carga en modo Debug (no en producción)
- [x] Solo se carga si la BD está vacía
- [x] No se carga en UI tests
- [x] Usuario de prueba incluido: Ana García López
- [x] Logging agregado para ver cuándo se cargan los datos

---

## 🎯 Próximos Pasos

1. **Compila la app:** `⌘ + B`
2. **Borra la app del simulador** (para empezar limpio)
3. **Ejecuta:** `⌘ + R`
4. **Verás en consola:**
   ```
   📊 No hay miembros en la BD. Cargando datos de prueba...
   ✅ Usuario de prueba agregado: Ana García López
   💾 Datos de prueba guardados en SwiftData
   ```
5. **La app mostrará el perfil** de Ana García automáticamente

---

## 🚀 Beneficios

- ✅ **No necesitas crear datos manualmente** cada vez que reseteas
- ✅ **Testing más rápido** - Siempre tienes datos para probar
- ✅ **Datos realistas** - El usuario de prueba tiene todos los campos rellenados
- ✅ **Fácil de extender** - Puedes agregar más usuarios fácilmente
- ✅ **No afecta a producción** - Solo funciona en modo Debug

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Archivos modificados:** PersistenceController.swift, AsociaApp.swift

# 🤖 Auto-Validación de Altas en Modo Local

Esta guía explica cómo funciona el sistema de **auto-validación automática** de solicitudes de alta cuando la app está en **esquema Local**.

---

## 🎯 ¿Qué Es Esto?

Cuando ejecutas la app en **modo Local** (conectada al backend en Docker), el sistema simula automáticamente la aprobación o rechazo de altas por parte del equipo gestor.

Esto te permite **probar el flujo completo** sin necesidad de:
- Acceder manualmente al backoffice
- Aprobar/rechazar cada solicitud a mano
- Esperar a que alguien procese las altas

---

## ⚙️ Cómo Funciona

### 1️⃣ **Envío de Solicitud**

Cuando envías una solicitud de alta en modo Local, el estado inicial es `pendingApproval` (como siempre).

### 2️⃣ **Auto-Validación Programada**

El sistema analiza el **nombre EXACTO** (no solo el primer carácter):

| Nombre EXACTO | Acción después de 8 segundos |
|----------------|------------------------------|
| **"A"** (solo la letra A) | ✅ **Aprobado** → Estado `active` |
| **"B"** (solo la letra B) | ❌ **Rechazado** → Estado `rejected` con razón |
| **Cualquier otro nombre** | ⏸️ **Sin acción** → Queda en `pendingApproval` |

⚠️ **IMPORTANTE**: Para que se auto-valide, el nombre debe ser EXACTAMENTE "A" o "B", no "Ana", "Antonio", "Beatriz", etc.

### 3️⃣ **Detección por SyncEngine**

El `SyncEngine` sincroniza periódicamente (cada 30 segundos) y detecta el cambio de estado automáticamente.

---

## 📋 Ejemplos

### ✅ Ejemplo 1: Alta Aprobada Automáticamente

**Registro:**
- **Nombre:** A (exactamente la letra "A")
- **Apellido:** García
- **Email:** ana@test.com

**Resultado:**
```
⏱️ [LOCAL-AUTO] Programada auto-validación para 'A' → APROBAR en 8 segundos
... (espera 8 segundos) ...
✅ [LOCAL-AUTO] AUTO-APROBANDO a 'A' (nombre = 'A')
🔔 [LOCAL-AUTO] Estado actualizado → active
```

**En la app:**
- A los 8 segundos, el estado cambia de `pendingApproval` a `active`
- El banner amarillo desaparece
- Se habilita el acceso al Chat
- **VES TUS PROPIOS DATOS, no los de ningún usuario de prueba**

---

### ❌ Ejemplo 2: Alta Rechazada Automáticamente

**Registro:**
- **Nombre:** B (exactamente la letra "B")
- **Apellido:** López
- **Email:** bea@test.com

**Resultado:**
```
⏱️ [LOCAL-AUTO] Programada auto-validación para 'B' → RECHAZAR en 8 segundos
... (espera 8 segundos) ...
❌ [LOCAL-AUTO] AUTO-RECHAZANDO a 'B' (nombre = 'B')
🔔 [LOCAL-AUTO] Estado actualizado → rejected
   Razón: "Auto-rechazado en modo Local (nombre = 'B')"
```

**En la app:**
- A los 8 segundos, el estado cambia a `rejected`
- Aparece un mensaje de error mostrando la razón del rechazo
- El usuario no puede acceder al Chat

---

### ⏸️ Ejemplo 3: Sin Auto-Validación

**Registro:**
- **Nombre:** Ana (o cualquier nombre que NO sea exactamente "A" o "B")
- **Apellido:** Martínez
- **Email:** ana@test.com

**Resultado:**
```
ℹ️ [LOCAL-AUTO] Nombre 'Ana' no requiere auto-validación (solo 'A' o 'B')
```

**En la app:**
- El estado queda en `pendingApproval` indefinidamente
- Se puede aprobar/rechazar manualmente desde el backoffice (si está implementado)

---

## 🎮 Cómo Probar

### 1️⃣ **Levantar el Backend**

```bash
cd backend
docker compose up --build
```

### 2️⃣ **Configurar Xcode en Modo Local**

1. **Product → Scheme → Asocia (Local)**
2. Verificar que la variable de entorno esté configurada:
   - **Product → Scheme → Edit Scheme**
   - **Run → Arguments → Environment Variables**
   - `ASOCIA_ENVIRONMENT = local` ✅

### 3️⃣ **Ejecutar la App**

```bash
⌘ + R
```

### 4️⃣ **Registrar un Usuario con Nombre "A..."**

1. Toca **"Asocia"** (botón de registro)
2. Completa el formulario:
   - **Nombre:** A (exactamente la letra "A" para que se auto-valide)
   - **Primer apellido:** Tu apellido
   - **Email:** tu@test.com
   - **Contraseña:** 123456
3. Envía

### 5️⃣ **Observar la Consola**

Deberías ver:

```
🚀 [SIGNUP] Iniciando envío de aplicación...
📤 [SIGNUP] Enviando aplicación al servidor...
📡 [API] submitMembershipApplication - Ana García
🔧 [LOCAL-AUTO] Interceptando submitMembershipApplication
   🌐 [POST] http://localhost:4000/v1/members/apply
   ✅ Response: 201
✅ [SIGNUP] Aplicación enviada
⏱️ [LOCAL-AUTO] Programada auto-validación para 'Ana' → APROBAR en 8 segundos
💾 [SIGNUP] Member guardado localmente

... (espera 8 segundos) ...

✅ [LOCAL-AUTO] AUTO-APROBANDO a 'A' (nombre = 'A') → http://localhost:4000/v1/admin/members/.../confirm
🔔 [LOCAL-AUTO] Confirmación persistida en la base de datos por membership-service

... (en el próximo sync, ~5 minutos, o al volver a primer plano) ...

📡 [SYNC] Sincronizando con el servidor...
✅ [SYNC] Estado actualizado a: active
```

### 6️⃣ **Verificar en la App**

- El banner amarillo desaparece a los 8 segundos
- El estado cambia a **"Activo"**
- Las pestañas de Chat y otras funciones se habilitan

---

## 🔍 Testing Diferentes Escenarios

### Escenario 1: Alta Aprobada
```swift
// Registrar con nombre: A (solo la letra A)
// Resultado: Aprobado a los 8 segundos
```

### Escenario 2: Alta Rechazada
```swift
// Registrar con nombre: B (solo la letra B)
// Resultado: Rechazado a los 8 segundos con mensaje
```

### Escenario 3: Sin Auto-Validación
```swift
// Registrar con nombre: Ana, Carlos, Diana, Eduardo, etc.
// Resultado: Queda pendiente indefinidamente
```

---

## ⚠️ Limitaciones y Notas

### Solo en Modo Local
Esta funcionalidad **SOLO funciona en esquema Local**. En otros entornos:
- **Mock:** No hace llamadas de red reales
- **Staging/Production:** Usa el backend real sin modificaciones

### Timing
El tiempo de espera es **exactamente 8 segundos** después del envío de la solicitud.

### SyncEngine
El cambio de estado se detecta cuando el `SyncEngine` hace un fetch, que ocurre:
- Al iniciar la app
- Cada 30 segundos automáticamente
- Al volver a primer plano

### Backend Real
La auto-validación llama a los mismos endpoints admin (`/v1/admin/members/:id/confirm` y `/reject`) que usaría el backoffice real, con la cabecera `x-admin-key`. El `UPDATE` queda persistido en la base de datos de `membership-service`, por lo que el estado se mantiene aunque se reinicie la app o se vuelva a entrar con un token de una sesión anterior.

---

## 🛠️ Personalización

Si quieres cambiar el comportamiento, edita `LocalAutoValidationAPIClient.swift`:

### Cambiar el Tiempo de Espera

```swift
// Línea ~85 - Cambiar de 8 a 5 segundos
try? await Task.sleep(for: .seconds(5))  // ← Cambiar aquí
```

### Cambiar las Reglas de Auto-Validación

```swift
// Línea ~64 - Cambiar la lógica
let action: ValidationAction
switch firstChar {
case "A":
    action = .approve
case "B":
    action = .reject
case "C":  // ← Agregar nueva regla
    action = .approve
default:
    action = .none
}
```

### Agregar Logging Adicional

```swift
// Agregar más prints para debugging
#if DEBUG
print("🐛 [DEBUG] Tu mensaje aquí")
#endif
```

---

## 📝 Checklist de Verificación

Para que funcione correctamente:

- [ ] ✅ Backend levantado (`docker compose up`)
- [ ] ✅ Scheme "Asocia (Local)" seleccionado
- [ ] ✅ Variable `ASOCIA_ENVIRONMENT=local` configurada
- [ ] ✅ Nombre del usuario empieza con "A" o "B"
- [ ] ✅ Esperar al menos 8 segundos después del registro
- [ ] ✅ SyncEngine sincroniza (automático cada 30s)

---

## 🎯 Casos de Uso

### Para Desarrolladores
- ✅ Probar el flujo completo de alta sin intervención manual
- ✅ Testing de estados: pendiente → aprobado → activo
- ✅ Testing de estados: pendiente → rechazado → error

### Para Diseñadores
- ✅ Ver cómo se ve la UI en cada estado
- ✅ Probar transiciones de estado
- ✅ Verificar mensajes de error

### Para QA
- ✅ Automatizar pruebas de flujo completo
- ✅ Verificar comportamiento en diferentes escenarios
- ✅ Probar edge cases (nombres vacíos, nombres raros, etc.)

---

## 🔗 Archivos Relacionados

- **`LocalAutoValidationAPIClient.swift`** - Lógica de auto-validación
- **`AsociaApp.swift`** - Inyección del wrapper en modo Local
- **`SyncEngine.swift`** - Sincronización periódica
- **`AppEnvironment.swift`** - Configuración de entornos

---

**Fecha:** 27 de julio de 2026  
**Versión:** 1.0  
**Modo:** Solo Local

¡Disfruta probando el flujo completo automáticamente! 🚀

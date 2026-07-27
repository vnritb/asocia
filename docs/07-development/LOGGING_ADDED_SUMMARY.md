# ✅ Logging Agregado a los Servicios

## 📋 Logging Agregado

### En APIClient.swift

1. ✅ **submitMembershipApplication()** - Muestra nombre y confirmación
2. ✅ **fetchCurrentMember()** - Muestra estado del miembro
3. ✅ **updateMember()** - Muestra nombre y confirmación
4. ✅ **send()** - Muestra:
   - Método HTTP y URL completa
   - Estado de autenticación
   - Status code de respuesta
   - Tiempo de respuesta en milisegundos
   - Emoji visual (✅ éxito / ❌ error)

### Características del Logging

- 📱 **Solo en Debug**: Todo el logging está dentro de `#if DEBUG`, no afecta a producción
- 🎨 **Visual**: Usa emojis para identificar rápidamente el tipo de log
- ⏱️ **Performance**: Muestra el tiempo de respuesta de cada petición
- 🔍 **Detallado**: Incluye URL completa, método, autenticación, status code

---

## 🚀 Cómo Usar

### 1. Ejecutar la App

```bash
⌘ + R
```

### 2. Abrir la Consola en Xcode

```
View → Debug Area → Activate Console
```

O usa el atajo: `⌘ + Shift + Y`

### 3. Filtrar Logs (Opcional)

En la barra de búsqueda de la consola, escribe:
- `📡` - Ver solo peticiones de API
- `[API]` - Ver solo APIClient
- `[POST]` - Ver solo peticiones POST
- `✅` - Ver solo respuestas exitosas
- `❌` - Ver solo errores

### 4. Realizar Acciones

- **Enviar formulario de alta** → Verás el POST a `/v1/members/apply`
- **Abrir la app** → Verás el GET a `/v1/members/me`
- **Editar perfil** → Verás el PATCH a `/v1/members/me`

---

## 🧪 Para Ver Servicios Mock

Si quieres ver cuándo se usan los **servicios mock** en vez de los reales, necesitas agregar logging similar a los mocks.

### Encontrar los Mocks

Busca archivos como:
- `Services/Mocks/MockMembershipAPIClient.swift`
- `Services/Mocks/MockChatService.swift`

### Agregar Logging (Ejemplo)

```swift
actor MockMembershipAPIClient: MembershipAPIClient {
    
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        #if DEBUG
        print("🧪 [MOCK] submitMembershipApplication - \(dto.firstName) \(dto.firstSurname)")
        #endif
        
        // ... código existente ...
        
        #if DEBUG
        print("   ✅ Mock application submitted")
        #endif
        
        return response
    }
    
    func fetchCurrentMember() async throws -> MemberDTO {
        #if DEBUG
        print("🧪 [MOCK] fetchCurrentMember")
        #endif
        
        // ... código existente ...
        
        #if DEBUG
        print("   ✅ Mock member fetched")
        #endif
        
        return member
    }
}
```

---

## 📊 Ejemplo de Consola Completa

### Al Iniciar la App

```
🚀 AsociaApp.task iniciado
✅ Localizaciones cargadas: ca, en, es, eu, gl
   SyncEngine inicializado

📡 [API] fetchCurrentMember
   🌐 [GET] http://localhost:3000/v1/members/me
   🔐 Authenticated: No
   ❌ No auth token available

   🧪 UI Test mode: Sin splash
   ✅ Splash oculto, mostrando RootView
```

### Al Enviar Alta

```
📡 [API] submitMembershipApplication - Ana García
   🌐 [POST] http://localhost:3000/v1/members/apply
   🔐 Authenticated: No
   ✅ Response: 201 (387ms)
   ✅ Application submitted - Token saved

📡 [API] fetchCurrentMember
   🌐 [GET] http://localhost:3000/v1/members/me
   🔐 Authenticated: Yes
   ✅ Response: 200 (156ms)
   ✅ Member fetched - Status: pendingApproval
```

---

## 🔍 Debugging Avanzado

### Ver el Body de las Peticiones

Si necesitas ver el contenido completo del body, agrega esto al método `send()`:

```swift
if let body {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let jsonData = try? encoder.encode(body),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print("   📤 Body:")
        print(jsonString)
    }
}
```

### Ver el Response Body

Después de recibir la respuesta:

```swift
if let responseString = String(data: data, encoding: .utf8) {
    print("   📥 Response:")
    print(responseString)
}
```

⚠️ **Advertencia:** Esto puede generar MUCHO output en la consola.

---

## ✅ Checklist de Verificación

- [x] Logging agregado a `submitMembershipApplication()`
- [x] Logging agregado a `fetchCurrentMember()`
- [x] Logging agregado a `updateMember()`
- [x] Logging agregado al método `send()` con detalles HTTP
- [x] Todo el logging está dentro de `#if DEBUG`
- [x] Se muestran URLs completas
- [x] Se muestra tiempo de respuesta
- [x] Se muestra status code
- [ ] (Opcional) Agregar logging a los mocks

---

## 🎯 Próximos Pasos

1. **Compila la app**: `⌘ + B`
2. **Ejecuta la app**: `⌘ + R`
3. **Abre la consola**: `⌘ + Shift + Y`
4. **Realiza acciones** (enviar alta, sincronizar, etc.)
5. **Observa los logs** en la consola

Ahora podrás ver **exactamente** qué peticiones se están haciendo, cuándo, a qué endpoints, con qué método, y cuánto tardan.

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0  
**Archivos modificados:** APIClient.swift

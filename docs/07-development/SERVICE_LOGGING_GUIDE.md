# 🔍 Cómo Verificar si los Servicios Están Recibiendo Peticiones

## 📊 Estado Actual

Actualmente, los servicios **NO tienen logging detallado** de las peticiones. Vamos a añadirlo.

---

## 🛠️ Solución 1: Agregar Logging a APIClient (Servicio Real)

### Modificar APIClient.swift

Agrega logging en el método `send()`:

```swift
private func send<Body: Encodable, Response: Decodable>(
    path: String, method: String, body: Body?, authenticated: Bool = true
) async throws -> Response {
    
    #if DEBUG
    print("📡 [\(method)] \(baseURL.appendingPathComponent(path).absoluteString)")
    if let body {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(body),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("   📤 Request Body:")
            print(jsonString)
        }
    }
    #endif
    
    var request = URLRequest(url: baseURL.appendingPathComponent(path))
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if authenticated {
        guard let authToken else { throw APIClientError.notAuthenticated }
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        #if DEBUG
        print("   🔐 Authenticated: \(authToken.prefix(20))...")
        #endif
    }

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if let body { request.httpBody = try encoder.encode(body) }

    #if DEBUG
    let startTime = Date()
    #endif
    
    let (data, response) = try await session.data(for: request)

    #if DEBUG
    let duration = Date().timeIntervalSince(startTime)
    #endif
    
    guard let http = response as? HTTPURLResponse else {
        #if DEBUG
        print("   ❌ Invalid HTTP response")
        #endif
        throw APIClientError.transport
    }
    
    #if DEBUG
    print("   📥 Response: \(http.statusCode) (\(String(format: "%.2f", duration * 1000))ms)")
    if let responseString = String(data: data, encoding: .utf8) {
        print("   📦 Response Body:")
        print(responseString)
    }
    #endif
    
    guard (200..<300).contains(http.statusCode) else {
        #if DEBUG
        print("   ❌ Server error: \(http.statusCode)")
        #endif
        throw APIClientError.server(statusCode: http.statusCode)
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(Response.self, from: data)
}
```

### Ejemplo de Output en Consola

```
📡 [POST] http://localhost:3000/v1/members/apply
   📤 Request Body:
{
  "address" : "Carrer Major 1",
  "city" : "Barcelona",
  "email" : "ana@example.com",
  "firstName" : "Ana",
  "firstSurname" : "García",
  ...
}
   📥 Response: 200 (245.32ms)
   📦 Response Body:
{
  "authToken": "eyJhbGciOiJIUzI1...",
  "member": { ... }
}

📡 [GET] http://localhost:3000/v1/members/me
   🔐 Authenticated: eyJhbGciOiJIUzI1...
   📥 Response: 200 (123.45ms)
   📦 Response Body:
{ ... }
```

---

## 🛠️ Solución 2: Agregar Logging a los Servicios Mock

### Crear un Mock con Logging

Crea un nuevo archivo `Services/Mocks/MockMembershipAPIClientWithLogging.swift`:

```swift
import Foundation

/// Mock del servicio de membresía con logging detallado para debugging
actor MockMembershipAPIClientWithLogging: MembershipAPIClient {
    
    private(set) var submitCalls: [MemberDTO] = []
    private(set) var fetchCalls = 0
    private(set) var updateCalls: [MemberDTO] = []
    
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        #if DEBUG
        print("🧪 [MOCK] submitMembershipApplication()")
        print("   📤 Member: \(dto.firstName) \(dto.firstSurname)")
        print("   📧 Email: \(dto.email)")
        print("   📱 Phone: \(dto.mobilePhone)")
        #endif
        
        submitCalls.append(dto)
        
        var applied = dto
        applied.membershipStatus = .pendingApproval
        
        let response = MembershipApplicationResponse(
            authToken: "mock-token-\(UUID().uuidString.prefix(8))",
            member: applied
        )
        
        #if DEBUG
        print("   ✅ Application submitted - Status: pendingApproval")
        #endif
        
        return response
    }
    
    func fetchCurrentMember() async throws -> MemberDTO {
        fetchCalls += 1
        
        #if DEBUG
        print("🧪 [MOCK] fetchCurrentMember() - Call #\(fetchCalls)")
        #endif
        
        // Simular que no hay miembro
        throw APIClientError.notAuthenticated
    }
    
    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        #if DEBUG
        print("🧪 [MOCK] updateMember()")
        print("   📤 Member: \(dto.firstName) \(dto.firstSurname)")
        print("   📧 Email: \(dto.email)")
        print("   🎫 Status: \(dto.membershipStatus)")
        #endif
        
        updateCalls.append(dto)
        
        #if DEBUG
        print("   ✅ Member updated")
        #endif
        
        return dto
    }
}
```

---

## 🛠️ Solución 3: Agregar Logging a ChatService

### Modificar ChatAPIClient.swift

Encuentra los métodos principales y agrega logging:

```swift
func fetchConversations() async -> [Conversation] {
    #if DEBUG
    print("💬 [CHAT] fetchConversations()")
    let startTime = Date()
    #endif
    
    // ... código existente ...
    
    #if DEBUG
    let duration = Date().timeIntervalSince(startTime)
    print("   ✅ Fetched \(conversations.count) conversations (\(String(format: "%.2f", duration * 1000))ms)")
    #endif
    
    return conversations
}

func sendMessage(_ content: String, to conversationID: UUID) async throws {
    #if DEBUG
    print("💬 [CHAT] sendMessage()")
    print("   📤 To conversation: \(conversationID)")
    print("   📝 Content: \(content.prefix(50))...")
    #endif
    
    // ... código existente ...
    
    #if DEBUG
    print("   ✅ Message sent")
    #endif
}
```

---

## 📊 Solución 4: Usar el Debugger de Xcode

### Configurar Breakpoints

1. **Abre APIClient.swift**
2. **Pon un breakpoint** en la línea que tiene:
   ```swift
   let (data, response) = try await session.data(for: request)
   ```
3. **Ejecuta la app** y realiza una acción que haga una petición
4. **Cuando el debugger pare**, inspecciona:
   - `request.url` - La URL completa
   - `request.httpMethod` - GET, POST, PATCH
   - `request.httpBody` - El cuerpo de la petición
   - `response` - La respuesta del servidor

### Ver Variables en el Debugger

```
(lldb) po request.url
▿ Optional<URL>
  - some : http://localhost:3000/v1/members/apply

(lldb) po request.httpMethod
▿ Optional<String>
  - some : "POST"

(lldb) po String(data: request.httpBody!, encoding: .utf8)
▿ Optional<String>
  - some : "{\"firstName\":\"Ana\",\"email\":\"ana@example.com\"...}"
```

---

## 📊 Solución 5: Network Link Conditioner (iOS)

### En el Simulador

1. **Abre la app Ajustes** en el simulador
2. **Ve a Developer → Network Link Conditioner**
3. **Activa el condicionador** y elige un perfil (ej: "3G")
4. **Ejecuta la app** y verás en la consola cuánto tardan las peticiones

---

## 🔍 Solución 6: Usar Proxyman o Charles Proxy

### Instalar Proxyman (Recomendado para macOS)

1. **Descarga** Proxyman: https://proxyman.io
2. **Instala el certificado SSL** en el simulador
3. **Ejecuta Proxyman** y luego tu app
4. **Verás TODAS las peticiones** HTTP/HTTPS en tiempo real:
   - URL
   - Método (GET, POST, etc.)
   - Headers
   - Body (request y response)
   - Tiempo de respuesta
   - Status code

### Ejemplo de lo que verás

```
📡 POST /v1/members/apply
   Status: 200 OK
   Duration: 245ms
   
   Request Headers:
   Content-Type: application/json
   
   Request Body:
   {
     "firstName": "Ana",
     "email": "ana@example.com",
     ...
   }
   
   Response Body:
   {
     "authToken": "eyJhbGc...",
     "member": { ... }
   }
```

---

## ✅ Checklist de Verificación

### Para Servicios Reales (APIClient)

- [ ] Agregar logging en método `send()`
- [ ] Ejecutar la app y realizar una acción (ej: enviar formulario de alta)
- [ ] Verificar en consola que aparecen logs como:
  ```
  📡 [POST] http://localhost:3000/v1/members/apply
  ```
- [ ] Verificar que aparece el response con status code

### Para Servicios Mock

- [ ] Verificar que en `AsociaApp.swift` se está usando el mock:
  ```swift
  if env.usesMockServices {
      apiClient = MockMembershipAPIClient()
      chatService = MockChatService()
  }
  ```
- [ ] Agregar logging en los métodos del mock
- [ ] Ejecutar la app y verificar logs como:
  ```
  🧪 [MOCK] submitMembershipApplication()
  ```

### Para Verificar qué Servicio se Está Usando

Agrega este log en `AsociaApp.swift`:

```swift
init() {
    // ... código existente ...
    
    if env.usesMockServices {
        apiClient = MockMembershipAPIClient()
        chatService = MockChatService()
        #if DEBUG
        print("🧪 Usando servicios MOCK")
        #endif
    } else {
        apiClient = APIClient(baseURL: env.apiBaseURL)
        chatService = ChatAPIClient(baseURL: env.apiBaseURL)
        #if DEBUG
        print("🌐 Usando servicios REALES - Base URL: \(env.apiBaseURL)")
        #endif
    }
}
```

---

## 🎯 Método Rápido: Solo Ver si Hay Peticiones

### Agregar esto al inicio de cada método en APIClient.swift

```swift
func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
    print("📡 submitMembershipApplication llamado")
    // ... resto del código
}

func fetchCurrentMember() async throws -> MemberDTO {
    print("📡 fetchCurrentMember llamado")
    // ... resto del código
}

func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
    print("📡 updateMember llamado")
    // ... resto del código
}
```

### Y en MockMembershipAPIClient

```swift
func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
    print("🧪 [MOCK] submitMembershipApplication llamado")
    // ... resto del código
}

func fetchCurrentMember() async throws -> MemberDTO {
    print("🧪 [MOCK] fetchCurrentMember llamado")
    // ... resto del código
}

func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
    print("🧪 [MOCK] updateMember llamado")
    // ... resto del código
}
```

---

## 📊 Ejemplo Completo de Output Esperado

### Al Arrancar la App

```
🚀 AsociaApp.task iniciado
🧪 Usando servicios MOCK
SyncEngine inicializado
✅ Localizaciones cargadas: ca, en, es, eu, gl
🧪 [MOCK] fetchCurrentMember llamado - Call #1
⏳ Esperando 1.2s para ocultar splash...
✅ Splash oculto, mostrando RootView
```

### Al Enviar Formulario de Alta

```
🧪 [MOCK] submitMembershipApplication llamado
   📤 Member: Ana García
   📧 Email: ana@example.com
   📱 Phone: 600123456
   ✅ Application submitted - Status: pendingApproval
```

### Al Sincronizar

```
🧪 [MOCK] fetchCurrentMember llamado - Call #2
   ✅ Member fetched - Status: active
```

---

## 🚀 Acción Recomendada

**La forma más rápida de empezar:**

1. **Agrega logging básico** en `AsociaApp.swift` para ver qué servicios se usan
2. **Agrega `print()` simple** al inicio de cada método en `APIClient.swift` y los mocks
3. **Ejecuta la app** y mira la consola
4. **Realiza acciones** (enviar alta, sincronizar, enviar mensaje) y verifica los logs

¿Quieres que te ayude a agregar el logging a algún servicio específico?

---

**Fecha:** 26 de julio de 2026  
**Versión:** 1.0

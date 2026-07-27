# 💬 Chat - Asocia

Sistema de mensajería y conversaciones.

---

## 📄 Documentos en esta Sección

### [CHAT_USERS_GUIDE.md](./CHAT_USERS_GUIDE.md)
**Guía de Usuarios del Chat**

Documentación del sistema de chat:
- 💬 Conversaciones individuales, grupales y de actividades
- 👥 Gestión de participantes
- 📱 UI del chat
- 🔔 Notificaciones (futuro)
- 📂 Estructura de datos

### [INFINITE_SCROLL_GUIDE.md](./INFINITE_SCROLL_GUIDE.md)
**Guía de Scroll Infinito**

Implementación de scroll infinito para listas:
- 📜 Scroll infinito en listas largas
- 📄 Paginación eficiente
- 🔄 Carga de más elementos
- ⚡ Optimización de rendimiento
- 🎨 UX durante la carga

---

## 🎯 Características del Chat

### Tipos de Conversaciones

1. **Individuales** 🗣️
   - Una conversación por pareja de usuarios
   - No duplicados
   - Avatar del otro usuario

2. **Grupos** 👥
   - Múltiples participantes
   - Nombre personalizable
   - Icono de grupo

3. **Actividades** 📅
   - Como grupos pero con calendario de eventos
   - Gestión de asistencia
   - Eventos próximos

---

## 🏗️ Arquitectura

### Servicios

```swift
protocol ChatServicing {
    func fetchConversations() async -> [Conversation]
    func searchDirectory(query: String, page: Int, pageSize: Int) async -> (users: [ChatUser], hasMore: Bool)
    func openOrCreateIndividualConversation(with: UUID) async throws -> Conversation
    func createGroupConversation(name: String, participantIDs: [UUID]) async throws -> Conversation
    func sendMessage(conversationID: UUID, text: String) async throws -> Message
}
```

### Modelos

```swift
struct Conversation: Identifiable {
    var id: UUID
    var kind: ConversationKind  // .individual, .group, .activity
    var title: String
    var participantIDs: [UUID]
    var lastMessagePreview: String
    var lastMessageAt: Date?
    var photoData: Data?
}

struct Message: Identifiable {
    var id: UUID
    var conversationID: UUID
    var senderID: UUID
    var text: String
    var sentAt: Date
}

struct ChatUser: Identifiable {
    var id: UUID
    var fullName: String
    var photoData: Data?
}
```

---

## 📜 Scroll Infinito

### Implementación

```swift
struct UserSearchView: View {
    @State private var results: [ChatUser] = []
    @State private var currentPage = 0
    @State private var hasMore = true
    @State private var isLoadingMore = false
    
    private let pageSize = 10
    
    var body: some View {
        List {
            ForEach(results) { user in
                UserRow(user: user)
                    .onAppear {
                        // Cargar más cuando lleguemos al último elemento
                        if results.last?.id == user.id && hasMore {
                            Task { await loadMore() }
                        }
                    }
            }
            
            if isLoadingMore {
                ProgressView()
            }
        }
    }
    
    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        currentPage += 1
        
        let response = await chatService.searchDirectory(
            query: query,
            page: currentPage,
            pageSize: pageSize
        )
        
        results.append(contentsOf: response.users)
        hasMore = response.hasMore
        isLoadingMore = false
    }
}
```

### Características

- ✅ Carga inicial pequeña (10 elementos)
- ✅ Carga automática al acercarse al final
- ✅ Indicador de carga
- ✅ Previene cargas duplicadas
- ✅ Eficiente con listas grandes

---

## 🧪 Testing

### Mock Service

```swift
actor MockChatService: ChatServicing {
    private var conversations: [Conversation] = []
    private var messages: [Message] = []
    
    // Implementación de prueba...
}
```

### Pruebas Unitarias

```swift
@Test func individualConversationIsUnique() async throws {
    let service = MockChatService()
    let user = try #require(await service.searchDirectory(query: "", page: 0, pageSize: 10).users.first)
    
    let conv1 = try await service.openOrCreateIndividualConversation(with: user.id)
    let conv2 = try await service.openOrCreateIndividualConversation(with: user.id)
    
    #expect(conv1.id == conv2.id)
}
```

---

## 🚀 Uso

### Búsqueda de Usuarios

```swift
// UserSearchView.swift
let response = await chatService.searchDirectory(
    query: "pedro",
    page: 0,
    pageSize: 10
)

for user in response.users {
    print("\(user.fullName)")
}

if response.hasMore {
    // Hay más resultados, cargar siguiente página
}
```

### Crear Conversación Individual

```swift
let conversation = try await chatService.openOrCreateIndividualConversation(
    with: otherUserID
)

// Si ya existía, devuelve la misma conversación
```

### Crear Grupo

```swift
let group = try await chatService.createGroupConversation(
    name: "Excursión Montaña",
    participantIDs: [user1ID, user2ID, user3ID]
)
```

### Enviar Mensaje

```swift
let message = try await chatService.sendMessage(
    conversationID: conversation.id,
    text: "Hola a todos!"
)
```

---

## 🔗 Enlaces Relacionados

- **Backend (paginación)**: [docs/04-backend/BACKEND_PAGINATION_GUIDE.md](../04-backend/BACKEND_PAGINATION_GUIDE.md)
- **Testing**: Ver `ChatServiceTests.swift` en el proyecto

---

**Última actualización:** 27 de julio de 2026

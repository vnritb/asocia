import Foundation

/// Respuesta vacía (204 No Content) decodificada como un objeto sin campos,
/// para poder reutilizar `send(...)` en endpoints que no devuelven cuerpo.
private struct EmptyResponse: Decodable {}

enum ChatAPIClientError: LocalizedError {
    case notAuthenticated
    case transport
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Sesión no iniciada."
        case .transport: return "No hay conexión con el servidor."
        case .server(let statusCode): return "Error del servidor (\(statusCode))."
        }
    }
}

/// Cliente HTTP real de `ChatServicing`, contra `chat-service` a través del
/// API Gateway (rutas `/v1/directory`, `/v1/conversations*`, `/v1/events*`).
///
/// Usa el mismo token de sesión que `APIClient` (emitido en el alta,
/// guardado en Keychain): el Gateway lo resuelve contra membership-service
/// y exige que el socio tenga el alta confirmada antes de dejar pasar
/// ninguna de estas rutas — ver `services/api-gateway/src/index.ts`.
///
/// Se activa en los entornos `.local`, `.staging` y `.production`
/// (`AppEnvironment`); en `.mock` se usa `MockChatService` en su lugar.
actor ChatAPIClient: ChatServicing {
    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?

    init(baseURL: URL = AppEnvironment.current.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.authToken = KeychainStore.loadToken()
    }

    // `configureCurrentUser` no hace falta contra el backend real: la
    // identidad la resuelve el Gateway a partir del Bearer token. Se deja
    // vacía para cumplir el protocolo `ChatServicing`.
    func configureCurrentUser(id: UUID, name: String, photoData: Data?) async {}

    func searchDirectory(query: String) async -> [ChatUser] {
        (try? await get("/v1/directory?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")) ?? []
    }

    func fetchConversations() async -> [Conversation] {
        (try? await get("/v1/conversations")) ?? []
    }

    func openOrCreateIndividualConversation(with otherUserID: UUID) async throws -> Conversation {
        struct Body: Encodable { var otherUserId: UUID }
        return try await post("/v1/conversations/individual", body: Body(otherUserId: otherUserID))
    }

    func createGroupConversation(name: String, participantIDs: [UUID]) async throws -> Conversation {
        struct Body: Encodable { var title: String; var participantIds: [UUID] }
        return try await post("/v1/conversations/group", body: Body(title: name, participantIds: participantIDs))
    }

    func createActivityConversation(name: String, participantIDs: [UUID], photoData: Data?) async throws -> Conversation {
        struct Body: Encodable { var title: String; var participantIds: [UUID]; var photoBase64: String? }
        return try await post(
            "/v1/conversations/activity",
            body: Body(title: name, participantIds: participantIDs, photoBase64: photoData?.base64EncodedString())
        )
    }

    func fetchMessages(conversationID: UUID) async -> [ChatMessage] {
        (try? await get("/v1/conversations/\(conversationID)/messages")) ?? []
    }

    func sendMessage(conversationID: UUID, text: String) async throws -> ChatMessage {
        struct Body: Encodable { var text: String }
        return try await post("/v1/conversations/\(conversationID)/messages", body: Body(text: text))
    }

    func fetchEvents(conversationID: UUID) async -> [ActivityEvent] {
        (try? await get("/v1/conversations/\(conversationID)/events")) ?? []
    }

    func confirmAttendance(eventID: UUID) async throws -> ActivityEvent {
        try await post("/v1/events/\(eventID)/confirm", body: Optional<Int>.none)
    }

    func fetchAllActivities() async -> [ActivitySummary] {
        (try? await get("/v1/conversations/activities")) ?? []
    }

    func requestAccessToActivity(conversationID: UUID) async throws {
        let _: EmptyResponse = try await post("/v1/conversations/\(conversationID)/request-access", body: Optional<Int>.none)
    }

    // MARK: - HTTP helpers

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await send(path: path, method: "GET", body: Optional<Int>.none)
    }

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body?) async throws -> Response {
        try await send(path: path, method: "POST", body: body)
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String, method: String, body: Body?
    ) async throws -> Response {
        guard let authToken else { throw ChatAPIClientError.notAuthenticated }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let body { request.httpBody = try encoder.encode(body) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChatAPIClientError.transport }
        guard (200..<300).contains(http.statusCode) else { throw ChatAPIClientError.server(statusCode: http.statusCode) }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }
}

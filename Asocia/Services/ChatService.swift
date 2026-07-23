import Foundation

/// Contracte del servei de Xat.
///
/// En un backend real, això seria un microservei propi (Chat/Messaging
/// service) amb WebSockets per a missatges en temps real i Postgres (o
/// similar) per a l'historial — veure docs/ARQUITECTURA.md, secció Xat.
/// Aquí es defineix com a protocol perquè la UI no depengui de si al
/// darrere hi ha el mock (`MockChatService`) o un client real.
protocol ChatServicing: Sendable {
    func configureCurrentUser(id: UUID, name: String, photoData: Data?) async
    func searchDirectory(query: String) async -> [ChatUser]
    func fetchConversations() async -> [Conversation]
    func openOrCreateIndividualConversation(with otherUserID: UUID) async throws -> Conversation
    func createGroupConversation(name: String, participantIDs: [UUID]) async throws -> Conversation
    func createActivityConversation(name: String, participantIDs: [UUID], photoData: Data?) async throws -> Conversation
    func fetchMessages(conversationID: UUID) async -> [ChatMessage]
    func sendMessage(conversationID: UUID, text: String) async throws -> ChatMessage

    /// Eventos (esdeveniments) de una sala de tipo `activity`. El
    /// backoffice es quien los crea; aquí solo se consultan.
    func fetchEvents(conversationID: UUID) async -> [ActivityEvent]
    /// El socio confirma su asistencia a un evento (pasa de `invited` a `confirmed`).
    func confirmAttendance(eventID: UUID) async throws -> ActivityEvent

    /// TODAS las actividades que existen, seas o no participante — para la
    /// vista "Todas las actividades" (`ActivitiesDirectoryView`).
    func fetchAllActivities() async -> [ActivitySummary]
    /// Solicita unirte a una actividad de la que todavía no formas parte.
    func requestAccessToActivity(conversationID: UUID) async throws
}

enum ChatServiceError: LocalizedError {
    case emptyGroupName
    case notEnoughParticipants
    case conversationNotFound
    case eventNotFound

    var errorDescription: String? {
        switch self {
        case .emptyGroupName: return "Ponle un nombre al grupo."
        case .notEnoughParticipants: return "Selecciona al menos una persona más."
        case .conversationNotFound: return "No se ha encontrado la conversación."
        case .eventNotFound: return "No se ha encontrado el evento."
        }
    }
}

/// Emulació en memòria del backend de Xat: directori de socis de mentida,
/// converses i missatges guardats en memòria del procés (es perden en
/// tancar l'app). Serveix per demostrar tot el flux — cercar, obrir un 1:1
/// (amb la regla d'unicitat), crear grups, enviar missatges — sense
/// necessitat d'un servidor real encara.
///
/// Com a detall de realisme, quan envies un missatge a una conversa
/// individual amb un usuari de mentida, al cap d'uns segons "respon" amb un
/// missatge predefinit, simulant l'altra banda d'una conversa real.
actor MockChatService: ChatServicing {

    private var currentUserID = UUID()
    private var currentUserName = "Jo"
    private var currentUserPhoto: Data?

    private var directory: [ChatUser]
    private var conversations: [UUID: Conversation] = [:]
    private var messages: [UUID: [ChatMessage]] = [:]
    private var events: [UUID: [ActivityEvent]] = [:] // conversationID -> eventos

    private let canned = [
        "Hola! Com anem?",
        "Perfecte, ens veiem a la propera trobada de l'associació.",
        "Gràcies per l'avís!",
        "Apuntat, hi seré.",
        "👍",
        "Ho miro i et dic alguna cosa."
    ]

    init() {
        directory = MockChatService.seedDirectory()
    }

    // MARK: - Configuració

    func configureCurrentUser(id: UUID, name: String, photoData: Data?) async {
        currentUserID = id
        currentUserName = name
        currentUserPhoto = photoData
        // Assegura que "jo" no apareix duplicat al directori de mentida.
        directory.removeAll { $0.fullName == name }
    }

    // MARK: - Directori / cerca

    /// Cerca "a l'estil Google": no un simple `contains`, sinó per
    /// similitud de text (`StringSimilarity`, el mateix criteri que fa
    /// servir chat-service amb pg_trgm al backend real). Així, cercar
    /// "Pedro Gimenez" troba abans "Pedro Jiménez" (similitud alta amb tot
    /// el nom) que "Antonio Giménez" (només coincideix el cognom).
    func searchDirectory(query: String) async -> [ChatUser] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return directory }

        return directory
            .map { user in (user: user, score: StringSimilarity.score(user.fullName, trimmed)) }
            .filter { $0.score > 0.15 || $0.user.fullName.localizedCaseInsensitiveContains(trimmed) }
            .sorted { $0.score > $1.score }
            .map(\.user)
    }

    // MARK: - Converses

    func fetchConversations() async -> [Conversation] {
        conversations.values
            .filter { $0.participantIDs.contains(currentUserID) }
            .sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
    }

    /// Només pot existir una conversa individual per parella d'usuaris:
    /// si ja n'hi ha una, la retorna en comptes de crear-ne una altra.
    func openOrCreateIndividualConversation(with otherUserID: UUID) async throws -> Conversation {
        if let existing = conversations.values.first(where: {
            $0.kind == .individual && Set($0.participantIDs) == Set([currentUserID, otherUserID])
        }) {
            return existing
        }

        let conversation = Conversation(
            id: UUID(), kind: .individual, title: "",
            participantIDs: [currentUserID, otherUserID],
            lastMessagePreview: "", lastMessageAt: nil
        )
        conversations[conversation.id] = conversation
        messages[conversation.id] = []
        return conversation
    }

    /// De grups se'n poden crear tants com es vulgui (sense restricció d'unicitat).
    func createGroupConversation(name: String, participantIDs: [UUID]) async throws -> Conversation {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw ChatServiceError.emptyGroupName }
        guard !participantIDs.isEmpty else { throw ChatServiceError.notEnoughParticipants }

        let conversation = Conversation(
            id: UUID(), kind: .group, title: trimmedName,
            participantIDs: participantIDs + [currentUserID],
            lastMessagePreview: "", lastMessageAt: nil
        )
        conversations[conversation.id] = conversation
        messages[conversation.id] = []
        return conversation
    }

    /// Igual que un grupo, pero de tipo `activity`: además de mensajes,
    /// tiene un calendario de eventos. En un backend real, solo el
    /// backoffice (administración) podría crear salas de este tipo; aquí,
    /// para poder verlo funcionar de punta a punta, se generan uno o dos
    /// eventos de ejemplo automáticamente al crearla.
    func createActivityConversation(name: String, participantIDs: [UUID], photoData: Data?) async throws -> Conversation {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw ChatServiceError.emptyGroupName }
        guard !participantIDs.isEmpty else { throw ChatServiceError.notEnoughParticipants }

        let allParticipants = participantIDs + [currentUserID]
        let conversation = Conversation(
            id: UUID(), kind: .activity, title: trimmedName,
            participantIDs: allParticipants,
            lastMessagePreview: "", lastMessageAt: nil, photoData: photoData
        )
        conversations[conversation.id] = conversation
        messages[conversation.id] = []
        events[conversation.id] = seedEvents(for: conversation, participantIDs: allParticipants)
        return conversation
    }

    // MARK: - Descubrir actividades

    /// A diferencia de `fetchConversations()` (solo las mías), esto devuelve
    /// TODAS las salas de tipo `activity`, seas o no participante, para que
    /// cualquier socio pueda descubrirlas y solicitar acceso.
    func fetchAllActivities() async -> [ActivitySummary] {
        conversations.values
            .filter { $0.kind == .activity }
            .map { conversation in
                let upcoming = (events[conversation.id] ?? [])
                    .filter { $0.startDate >= .now }
                    .map(\.startDate)
                    .min()
                return ActivitySummary(
                    conversation: conversation,
                    isParticipant: conversation.participantIDs.contains(currentUserID),
                    nextEventDate: upcoming
                )
            }
            .sorted { ($0.nextEventDate ?? .distantFuture) < ($1.nextEventDate ?? .distantFuture) }
    }

    /// En este mock la solicitud se aprueba al instante (para poder ver el
    /// flujo completo sin backoffice). El backend real (`chat-service`) NO
    /// hace esto: guarda la solicitud pendiente de aprobación manual — ver
    /// `POST /v1/conversations/:id/request-access` en
    /// `backend/services/chat-service/src/index.ts`.
    func requestAccessToActivity(conversationID: UUID) async throws {
        guard var conversation = conversations[conversationID], conversation.kind == .activity else {
            throw ChatServiceError.conversationNotFound
        }
        guard !conversation.participantIDs.contains(currentUserID) else { return }
        conversation.participantIDs.append(currentUserID)
        conversations[conversationID] = conversation
    }

    // MARK: - Eventos

    func fetchEvents(conversationID: UUID) async -> [ActivityEvent] {
        (events[conversationID] ?? []).sorted { $0.startDate < $1.startDate }
    }

    @discardableResult
    func confirmAttendance(eventID: UUID) async throws -> ActivityEvent {
        for (conversationID, list) in events {
            guard let index = list.firstIndex(where: { $0.id == eventID }) else { continue }
            var updated = list
            if let attendeeIndex = updated[index].attendees.firstIndex(where: { $0.id == currentUserID }) {
                updated[index].attendees[attendeeIndex].status = .confirmed
            } else {
                updated[index].attendees.append(EventAttendee(id: currentUserID, name: currentUserName, status: .confirmed))
            }
            events[conversationID] = updated
            return updated[index]
        }
        throw ChatServiceError.eventNotFound
    }

    private func seedEvents(for conversation: Conversation, participantIDs: [UUID]) -> [ActivityEvent] {
        let invitees = participantIDs
            .compactMap { id -> EventAttendee? in
                if id == currentUserID {
                    return EventAttendee(id: id, name: currentUserName, status: .invited)
                }
                guard let user = directory.first(where: { $0.id == id }) else { return nil }
                return EventAttendee(id: id, name: user.fullName, status: .invited)
            }

        let first = ActivityEvent(
            id: UUID(), conversationID: conversation.id,
            title: "Quedada de bienvenida",
            eventDescription: "Primer encuentro del grupo \"\(conversation.title)\". Trae algo para compartir.",
            startDate: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
            endDate: nil, location: "Local de la asociación",
            attendees: invitees
        )
        return [first]
    }

    // MARK: - Missatges

    func fetchMessages(conversationID: UUID) async -> [ChatMessage] {
        messages[conversationID] ?? []
    }

    @discardableResult
    func sendMessage(conversationID: UUID, text: String) async throws -> ChatMessage {
        guard var conversation = conversations[conversationID] else {
            throw ChatServiceError.conversationNotFound
        }

        let message = ChatMessage(
            id: UUID(), conversationID: conversationID, senderID: currentUserID,
            senderName: currentUserName, text: text, sentAt: .now
        )
        messages[conversationID, default: []].append(message)

        conversation.lastMessagePreview = text
        conversation.lastMessageAt = message.sentAt
        conversations[conversationID] = conversation

        scheduleSimulatedReplyIfNeeded(for: conversation)
        return message
    }

    // MARK: - Simulació de resposta

    private func scheduleSimulatedReplyIfNeeded(for conversation: Conversation) {
        guard conversation.kind == .individual,
              let otherID = conversation.otherParticipantID(currentUserID: currentUserID),
              let otherUser = directory.first(where: { $0.id == otherID }) else { return }

        Task {
            try? await Task.sleep(for: .seconds(Double.random(in: 1.5...3)))
            let reply = ChatMessage(
                id: UUID(), conversationID: conversation.id, senderID: otherID,
                senderName: otherUser.fullName, text: canned.randomElement() ?? "👍", sentAt: .now
            )
            messages[conversation.id, default: []].append(reply)

            if var updated = conversations[conversation.id] {
                updated.lastMessagePreview = reply.text
                updated.lastMessageAt = reply.sentAt
                conversations[conversation.id] = updated
            }
        }
    }

    // MARK: - Dades de mentida

    private static func seedDirectory() -> [ChatUser] {
        [
            "Marta Puig", "Jordi Serra", "Laia Font", "Pol Vidal",
            "Núria Camps", "Àlex Ribas", "Clara Soler", "Bernat Roca",
            "Gemma Vila", "Oriol Mas", "Pedro Jiménez", "Antonio Giménez"
        ].map { ChatUser(id: UUID(), fullName: $0, photoData: nil) }
    }
}

/// Similitud de text "a l'estil Google" per a la cerca de socis, perquè
/// una errada o variant ortogràfica (p.ex. "Gimenez" en comptes de
/// "Giménez") no impedeixi trobar la persona correcta. Fa servir el
/// coeficient de Dice sobre bigrames de caràcters — el mateix principi que
/// `pg_trgm`/`similarity()` al backend real (chat-service), perquè el mode
/// mock i el mode real ordenin els resultats igual.
enum StringSimilarity {
    /// Puntuació entre 0 (cap coincidència) i 1 (idèntiques), ignorant
    /// majúscules/minúscules i accents.
    static func score(_ a: String, _ b: String) -> Double {
        let bigramsA = bigrams(of: a)
        let bigramsB = bigrams(of: b)
        guard !bigramsA.isEmpty, !bigramsB.isEmpty else { return 0 }

        let intersectionCount = bigramsA.intersectionCount(with: bigramsB)
        return (2.0 * Double(intersectionCount)) / Double(bigramsA.count + bigramsB.count)
    }

    private static func bigrams(of text: String) -> Multiset {
        let normalized = text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let chars = Array(normalized)
        guard chars.count > 1 else { return Multiset([normalized]) }

        var result: [String] = []
        for i in 0..<(chars.count - 1) {
            result.append(String(chars[i...i + 1]))
        }
        return Multiset(result)
    }

    /// Petit multiconjunt perquè bigrames repetits (p.ex. "aa") comptin
    /// correctament a la intersecció, tal com fa `similarity()` de pg_trgm.
    private struct Multiset {
        private var counts: [String: Int] = [:]
        var count: Int { counts.values.reduce(0, +) }
        var isEmpty: Bool { counts.isEmpty }

        init(_ items: [String]) {
            for item in items { counts[item, default: 0] += 1 }
        }

        func intersectionCount(with other: Multiset) -> Int {
            var total = 0
            for (key, value) in counts {
                total += min(value, other.counts[key] ?? 0)
            }
            return total
        }
    }
}

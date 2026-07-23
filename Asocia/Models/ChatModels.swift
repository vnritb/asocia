import Foundation

/// Un membre tal com apareix al directori de Xat (només socis amb l'alta
/// confirmada hi surten — ho garanteix el backend real; el `MockChatService`
/// ho simula amb un directori fix).
struct ChatUser: Identifiable, Codable, Sendable, Hashable {
    var id: UUID
    var fullName: String
    var photoData: Data?
}

enum ConversationKind: String, Codable, Sendable {
    case individual
    case group
    /// Sala especial que además de mensajes tiene un calendario de eventos
    /// (excursiones, quedadas, actos de la asociación...) gestionado por el
    /// equipo administrador desde el backoffice. Cualquier socio de la sala
    /// puede consultar los eventos y confirmar su asistencia.
    case activity
}

/// Una sala de conversa (individual o de grup).
///
/// Regla de negoci important: només pot existir UNA conversa `individual`
/// entre cada parella d'usuaris (ho garanteix `ChatServicing.openOrCreateIndividualConversation`).
/// De grups se'n poden crear tots els que es vulgui.
struct Conversation: Identifiable, Codable, Sendable, Hashable {
    var id: UUID
    var kind: ConversationKind
    /// Nom del grup. Buit per a converses individuals (el títol es calcula
    /// a la UI a partir de l'altre participant).
    var title: String
    var participantIDs: [UUID]
    var lastMessagePreview: String
    var lastMessageAt: Date?
    /// Foto de la sala. Solo se usa (de momento) en salas de tipo `activity`,
    /// para el listado grande de "Todas las actividades" — ver `ActivitiesDirectoryView`.
    var photoData: Data? = nil

    /// Per a una conversa individual, calcula l'ID de "l'altra persona".
    func otherParticipantID(currentUserID: UUID) -> UUID? {
        guard kind == .individual else { return nil }
        return participantIDs.first { $0 != currentUserID }
    }
}

struct ChatMessage: Identifiable, Codable, Sendable, Hashable {
    var id: UUID
    var conversationID: UUID
    var senderID: UUID
    var senderName: String
    var text: String
    var sentAt: Date
}

/// Estado de un socio frente a un evento: invitado (todavía no ha
/// respondido) o confirmado (ha dicho que asiste). El administrador decide
/// a quién invita desde el backoffice; el socio, desde la app, solo puede
/// pasar de "invitado" a "confirmado".
enum EventAttendeeStatus: String, Codable, Sendable {
    case invited
    case confirmed
}

struct EventAttendee: Identifiable, Codable, Sendable, Hashable {
    var id: UUID // = userID
    var name: String
    var status: EventAttendeeStatus
}

/// Un evento (esdeveniment) dentro de una sala de tipo `activity`: nombre,
/// descripción, fecha/lugar y lista de asistentes con su estado.
struct ActivityEvent: Identifiable, Codable, Sendable, Hashable {
    var id: UUID
    var conversationID: UUID
    var title: String
    var eventDescription: String
    var startDate: Date
    var endDate: Date?
    var location: String
    var attendees: [EventAttendee]

    func attendee(id userID: UUID) -> EventAttendee? {
        attendees.first { $0.id == userID }
    }
}

/// Resumen de una actividad para el listado "Todas las actividades"
/// (`ActivitiesDirectoryView`): a diferencia de `fetchConversations()`, que
/// solo devuelve las salas de las que YA formas parte, esto incluye
/// cualquier actividad exista o no seas participante — así cualquier socio
/// puede descubrirlas y solicitar acceso.
struct ActivitySummary: Identifiable, Codable, Sendable, Hashable {
    var conversation: Conversation
    var isParticipant: Bool
    /// Fecha del próximo evento (el más cercano en el futuro), o `nil` si no
    /// tiene ninguno programado.
    var nextEventDate: Date?

    var id: UUID { conversation.id }
}

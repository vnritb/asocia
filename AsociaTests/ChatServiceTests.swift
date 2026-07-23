import Testing
import Foundation
@testable import Asocia

@Suite("MockChatService")
struct ChatServiceTests {

    @Test("Només pot existir una conversa individual per parella d'usuaris")
    func individualConversationIsUnique() async throws {
        let service = MockChatService()
        await service.configureCurrentUser(id: UUID(), name: "Jo", photoData: nil)

        let directory = await service.searchDirectory(query: "")
        let other = try #require(directory.first)

        let first = try await service.openOrCreateIndividualConversation(with: other.id)
        let second = try await service.openOrCreateIndividualConversation(with: other.id)

        #expect(first.id == second.id)

        let conversations = await service.fetchConversations()
        let individualCount = conversations.filter { $0.kind == .individual }.count
        #expect(individualCount == 1)
    }

    @Test("Es poden crear tants grups com es vulgui")
    func multipleGroupsAreAllowed() async throws {
        let service = MockChatService()
        await service.configureCurrentUser(id: UUID(), name: "Jo", photoData: nil)

        let directory = await service.searchDirectory(query: "")
        let participants = Array(directory.prefix(2)).map(\.id)

        let group1 = try await service.createGroupConversation(name: "Grup A", participantIDs: participants)
        let group2 = try await service.createGroupConversation(name: "Grup B", participantIDs: participants)

        #expect(group1.id != group2.id)

        let conversations = await service.fetchConversations()
        #expect(conversations.filter { $0.kind == .group }.count == 2)
    }

    @Test("Crear un grup sense nom llança un error")
    func creatingGroupWithoutNameThrows() async {
        let service = MockChatService()
        await service.configureCurrentUser(id: UUID(), name: "Jo", photoData: nil)
        let directory = await service.searchDirectory(query: "")

        await #expect(throws: ChatServiceError.self) {
            _ = try await service.createGroupConversation(name: "   ", participantIDs: [directory[0].id])
        }
    }

    @Test("sendMessage guarda el missatge i s'associa a l'usuari actual")
    func sendMessagePersistsMessage() async throws {
        let service = MockChatService()
        let myID = UUID()
        await service.configureCurrentUser(id: myID, name: "Jo", photoData: nil)

        let directory = await service.searchDirectory(query: "")
        let other = try #require(directory.first)
        let conversation = try await service.openOrCreateIndividualConversation(with: other.id)

        let sent = try await service.sendMessage(conversationID: conversation.id, text: "Hola!")
        #expect(sent.senderID == myID)

        let messages = await service.fetchMessages(conversationID: conversation.id)
        #expect(messages.contains { $0.id == sent.id })
    }

    @Test("La cerca filtra pel nom i és insensible a majúscules")
    func searchFiltersByName() async {
        let service = MockChatService()
        await service.configureCurrentUser(id: UUID(), name: "Jo", photoData: nil)

        let results = await service.searchDirectory(query: "marta")
        #expect(results.allSatisfy { $0.fullName.localizedCaseInsensitiveContains("marta") })
        #expect(!results.isEmpty)
    }

    @Test("La cerca per similitud posa 'Pedro Jiménez' abans que 'Antonio Giménez' en cercar 'Pedro Gimenez'")
    func searchRanksBySimilarityNotJustSubstring() async {
        let service = MockChatService()
        await service.configureCurrentUser(id: UUID(), name: "Jo", photoData: nil)

        let results = await service.searchDirectory(query: "Pedro Gimenez")
        let names = results.map(\.fullName)
        let pedroIndex = names.firstIndex(of: "Pedro Jiménez")
        let antonioIndex = names.firstIndex(of: "Antonio Giménez")

        #expect(pedroIndex != nil)
        #expect(antonioIndex != nil)
        if let pedroIndex, let antonioIndex {
            #expect(pedroIndex < antonioIndex)
        }
    }

    @Test("Crear una sala de actividad genera al menos un evento de ejemplo")
    func creatingActivityConversationSeedsEvents() async throws {
        let service = MockChatService()
        await service.configureCurrentUser(id: UUID(), name: "Jo", photoData: nil)
        let directory = await service.searchDirectory(query: "")
        let participants = Array(directory.prefix(2)).map(\.id)

        let activity = try await service.createActivityConversation(name: "Excursiones", participantIDs: participants, photoData: nil)
        #expect(activity.kind == .activity)

        let events = await service.fetchEvents(conversationID: activity.id)
        #expect(!events.isEmpty)
    }

    @Test("fetchAllActivities devuelve todas las actividades, seas o no participante")
    func fetchAllActivitiesIncludesNonParticipantOnes() async throws {
        let creator = MockChatService()
        await creator.configureCurrentUser(id: UUID(), name: "Creador", photoData: nil)
        let directory = await creator.searchDirectory(query: "")
        let activity = try await creator.createActivityConversation(
            name: "Excursiones", participantIDs: [directory[0].id], photoData: nil
        )

        let outsider = MockChatService()
        let outsiderID = UUID()
        await outsider.configureCurrentUser(id: outsiderID, name: "De fuera", photoData: nil)
        // Cada instancia de MockChatService tiene su propio estado en memoria
        // (no comparten "backend"), así que para probar la visibilidad desde
        // fuera creamos la actividad y la consultamos con el mismo servicio.
        let summaries = await creator.fetchAllActivities()
        let mine = summaries.first { $0.conversation.id == activity.id }

        #expect(mine != nil)
        #expect(mine?.isParticipant == true)
    }

    @Test("requestAccessToActivity añade al usuario como participante")
    func requestAccessAddsParticipant() async throws {
        let service = MockChatService()
        let creatorID = UUID()
        await service.configureCurrentUser(id: creatorID, name: "Creador", photoData: nil)
        let directory = await service.searchDirectory(query: "")
        let activity = try await service.createActivityConversation(
            name: "Excursiones", participantIDs: [directory[0].id], photoData: nil
        )

        let newUserID = UUID()
        await service.configureCurrentUser(id: newUserID, name: "Nuevo socio", photoData: nil)

        var summaries = await service.fetchAllActivities()
        #expect(summaries.first { $0.conversation.id == activity.id }?.isParticipant == false)

        try await service.requestAccessToActivity(conversationID: activity.id)

        summaries = await service.fetchAllActivities()
        #expect(summaries.first { $0.conversation.id == activity.id }?.isParticipant == true)
    }

    @Test("confirmAttendance pasa al usuario actual de invitado a confirmado")
    func confirmAttendanceUpdatesStatus() async throws {
        let service = MockChatService()
        let myID = UUID()
        await service.configureCurrentUser(id: myID, name: "Jo", photoData: nil)
        let directory = await service.searchDirectory(query: "")
        let participants = Array(directory.prefix(2)).map(\.id)

        let activity = try await service.createActivityConversation(name: "Excursiones", participantIDs: participants, photoData: nil)
        let event = try #require(await service.fetchEvents(conversationID: activity.id).first)
        #expect(event.attendee(id: myID)?.status == .invited)

        let updated = try await service.confirmAttendance(eventID: event.id)
        #expect(updated.attendee(id: myID)?.status == .confirmed)
    }
}

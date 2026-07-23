import Testing
import Foundation
import SwiftData
@testable import Asocia

@Suite("SyncEngine")
@MainActor
struct SyncEngineTests {

    private func makeInMemoryContext() -> ModelContext {
        let schema = Schema([Member.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }

    private func sampleDTO(id: UUID = UUID(), status: MembershipStatus = .active) -> MemberDTO {
        MemberDTO(
            id: id, firstName: "Ana", firstSurname: "García", secondSurname: "López",
            email: "ana@example.com", secondaryEmail: "", mobilePhone: "600123456", landlinePhone: "",
            address: "Carrer Major 1", postalCode: "08001", city: "Barcelona", province: "Barcelona",
            birthDate: Date(timeIntervalSince1970: 0), entryYear: "2010", exitYear: "2012",
            promotion: "2012", profession: "", workplace: "", iban: "",
            facebookUsername: "", instagramUsername: "", xUsername: "", tiktokUsername: "",
            photoBase64: nil, isSearchable: false, associationID: nil, isVisibleToOtherAssociations: false,
            membershipStatus: status, joinDate: .now, rejectionReason: nil, updatedAt: .now
        )
    }

    @Test("syncNow() crea localment el soci que ja existeix al servidor")
    func pullCreatesLocalMemberWhenMissing() async {
        let context = makeInMemoryContext()
        let remote = sampleDTO(status: .active)
        let mock = SyncTestMembershipAPIClient(fetchResult: .success(remote))
        let engine = SyncEngine(apiClient: mock, modelContext: context)

        await engine.syncNow()

        let members = try! context.fetch(FetchDescriptor<Member>())
        #expect(members.count == 1)
        #expect(members.first?.id == remote.id)
        #expect(members.first?.membershipStatus == .active)
        #expect(members.first?.syncStatus == .synced)
        #expect(engine.lastSyncError == nil)
    }

    @Test("syncNow() puja els canvis locals pendents i els marca synced")
    func pushUploadsPendingLocalChanges() async {
        let context = makeInMemoryContext()
        let id = UUID()

        let local = Member(
            id: id, firstName: "Ana", firstSurname: "García (editat)",
            email: "ana@example.com", mobilePhone: "699000000", address: "Carrer Major 1",
            postalCode: "08001", city: "Barcelona", province: "Barcelona",
            membershipStatus: .active, syncStatus: .pendingUpload
        )
        context.insert(local)

        // El servidor, abans de la pujada, encara té el telèfon antic: així
        // comprovem que el que es puja és el local, no el remot.
        let remoteBeforePush = sampleDTO(id: id, status: .active)
        let mock = SyncTestMembershipAPIClient(fetchResult: .success(remoteBeforePush))
        let engine = SyncEngine(apiClient: mock, modelContext: context)

        await engine.syncNow()

        let updateCalls = await mock.updateCalls
        #expect(updateCalls.count == 1)
        #expect(updateCalls.first?.mobilePhone == "699000000")
        #expect(local.syncStatus == .synced)
    }

    @Test("Un fallo de xarxa deixa el soci marcat com syncFailed, sense perdre les dades locals")
    func networkFailureMarksSyncFailed() async {
        let context = makeInMemoryContext()
        let local = Member(
            firstName: "Ana", firstSurname: "García", email: "ana@example.com",
            mobilePhone: "600123456", address: "Carrer Major 1",
            postalCode: "08001", city: "Barcelona", province: "Barcelona", syncStatus: .pendingUpload
        )
        context.insert(local)

        let mock = SyncTestMembershipAPIClient(
            fetchResult: .failure(APIClientError.transport),
            updateError: APIClientError.transport
        )
        let engine = SyncEngine(apiClient: mock, modelContext: context)

        await engine.syncNow()

        #expect(engine.lastSyncError != nil)
        #expect(local.syncStatus == .syncFailed)
        #expect(local.firstName == "Ana") // les dades locals no es perden
    }
}

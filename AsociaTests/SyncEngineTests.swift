import Testing
import Foundation
import SwiftData
@testable import Asocia

/// Mock implementation of MembershipAPIClient for SyncEngine tests.
/// Using @MainActor to avoid isolation issues with SyncEngine tests.
@MainActor
final class MockMembershipAPIClientForTests: MembershipAPIClient {
    
    var fetchResult: Result<MemberDTO, Error>
    var updateError: Error?
    private(set) var updateCalls: [MemberDTO] = []
    
    init(fetchResult: Result<MemberDTO, Error>, updateError: Error? = nil) {
        self.fetchResult = fetchResult
        self.updateError = updateError
    }
    
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        if let error = updateError {
            throw error
        }
        updateCalls.append(dto)
        return MembershipApplicationResponse(authToken: "mock-token", member: dto)
    }
    
    func fetchCurrentMember() async throws -> MemberDTO {
        switch fetchResult {
        case .success(let dto):
            return dto
        case .failure(let error):
            throw error
        }
    }
    
    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        if let error = updateError {
            throw error
        }
        updateCalls.append(dto)
        return dto
    }
}

/// Mock implementation of MemberDataSource for testing
@MainActor
final class MockMemberDataSource: MemberDataSource {
    private var members: [Member] = []
    private(set) var saveCalled = false
    
    func fetchPendingMembers() throws -> [Member] {
        members.filter { $0.syncStatus == .pendingUpload }
    }
    
    func fetchMember(byID id: UUID) throws -> Member? {
        members.first(where: { $0.id == id })
    }
    
    func insertMember(_ member: Member) {
        members.append(member)
    }
    
    func save() throws {
        saveCalled = true
    }
    
    // Helper methods for tests
    func addMember(_ member: Member) {
        members.append(member)
    }
    
    func allMembers() -> [Member] {
        members
    }
}

@Suite("SyncEngine") @MainActor
struct SyncEngineTests {

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
    func pullCreatesLocalMemberWhenMissing() async throws {
        let dataSource = MockMemberDataSource()
        let remote = sampleDTO(status: .active)
        let mock = MockMembershipAPIClientForTests(fetchResult: .success(remote))
        let engine = SyncEngine(apiClient: mock, dataSource: dataSource)

        await engine.syncNow()

        let members = dataSource.allMembers()
        #expect(members.count == 1, "Debe haber exactamente 1 miembro")
        #expect(members.first?.id == remote.id, "El ID debe coincidir")
        #expect(members.first?.membershipStatus == .active, "El estado debe ser active")
        #expect(members.first?.syncStatus == .synced, "El syncStatus debe ser synced")
        #expect(engine.lastSyncError == nil, "No debe haber errores de sync")
    }

    @Test("syncNow() puja els canvis locals pendents i els marca synced")
    func pushUploadsPendingLocalChanges() async throws {
        let dataSource = MockMemberDataSource()
        let id = UUID()

        let local = Member(
            id: id, firstName: "Ana", firstSurname: "García (editat)",
            email: "ana@example.com", mobilePhone: "699000000", address: "Carrer Major 1",
            postalCode: "08001", city: "Barcelona", province: "Barcelona",
            membershipStatus: .active, syncStatus: .pendingUpload
        )
        dataSource.addMember(local)

        let remoteBeforePush = sampleDTO(id: id, status: .active)
        let mock = MockMembershipAPIClientForTests(fetchResult: .success(remoteBeforePush))
        let engine = SyncEngine(apiClient: mock, dataSource: dataSource)

        await engine.syncNow()

        #expect(mock.updateCalls.count == 1, "Debe haber exactamente 1 llamada a updateMember")
        #expect(mock.updateCalls.first?.mobilePhone == "699000000", "El teléfono debe ser el editado localmente")
        #expect(local.syncStatus == .synced, "El estado debe cambiar a synced")
    }

    @Test("Un fallo de xarxa deixa el soci marcat com syncFailed, sense perdre les dades locals")
    func networkFailureMarksSyncFailed() async throws {
        let dataSource = MockMemberDataSource()
        let local = Member(
            firstName: "Ana", firstSurname: "García", email: "ana@example.com",
            mobilePhone: "600123456", address: "Carrer Major 1",
            postalCode: "08001", city: "Barcelona", province: "Barcelona", syncStatus: .pendingUpload
        )
        dataSource.addMember(local)

        let mock = MockMembershipAPIClientForTests(
            fetchResult: .failure(APIClientError.transport),
            updateError: APIClientError.transport
        )
        let engine = SyncEngine(apiClient: mock, dataSource: dataSource)

        await engine.syncNow()

        #expect(engine.lastSyncError != nil, "Debe haber un error de sync registrado")
        #expect(local.syncStatus == .syncFailed, "El estado debe cambiar a syncFailed")
        #expect(local.firstName == "Ana", "Los datos locales no deben perderse")
    }
}


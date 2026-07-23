import Foundation
@testable import Asocia

/// Doble de test de `MembershipAPIClient`: permet provar `SyncEngine` sense
/// tocar la xarxa real. Es configura de forma async perquè és un `actor`
/// (igual que l'`APIClient` real), la qual cosa evita condicions de cursa
/// entre el test i el motor de sincronització.
///
/// Es diu `SyncTest...` (i no `MockMembershipAPIClient`, a seques) per no
/// xocar amb `Asocia/Services/Mocks/MockMembershipAPIClient.swift`, que és
/// la implementació mock que fa servir la pròpia app en `AppEnvironment.mock`
/// (objectiu diferent: demostrar el flux complet a la UI, no controlar
/// resultats exactes per a asserts de test).
actor SyncTestMembershipAPIClient: MembershipAPIClient {

    private(set) var updateCalls: [MemberDTO] = []
    private(set) var fetchCallCount = 0

    private var fetchResult: Result<MemberDTO, Error>
    private var updateError: Error?
    private var updateResultProvider: (@Sendable (MemberDTO) -> MemberDTO)?

    init(fetchResult: Result<MemberDTO, Error>, updateError: Error? = nil) {
        self.fetchResult = fetchResult
        self.updateError = updateError
    }

    func setFetchResult(_ result: Result<MemberDTO, Error>) {
        fetchResult = result
    }

    func setUpdateResultProvider(_ provider: @escaping @Sendable (MemberDTO) -> MemberDTO) {
        updateResultProvider = provider
    }

    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        var applied = dto
        applied.membershipStatus = .pendingApproval
        return MembershipApplicationResponse(authToken: "test-token", member: applied)
    }

    func fetchCurrentMember() async throws -> MemberDTO {
        fetchCallCount += 1
        return try fetchResult.get()
    }

    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        if let updateError { throw updateError }
        updateCalls.append(dto)
        return updateResultProvider?(dto) ?? dto
    }
}

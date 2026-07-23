import Foundation

/// Implementación "de mentira" de `MembershipAPIClient`, usada cuando
/// `AppEnvironment.current == .mock`: no abre ninguna conexión de red, todo
/// vive en memoria. Pensada para desarrollar/probar la UI de la app sin
/// necesidad de levantar el backend (ni siquiera con Docker).
///
/// Para que se pueda ver el ciclo completo de una alta sin backoffice real,
/// simula la aprobación: unos segundos después de enviar la solicitud, el
/// socio pasa solo de `pendingApproval` a `active` (el próximo `syncNow()`
/// de `SyncEngine`, que ya se dispara al arrancar la app, lo recoge).
actor MockMembershipAPIClient: MembershipAPIClient {
    private var member: MemberDTO?
    private let approvalDelay: Duration

    init(approvalDelay: Duration = .seconds(8)) {
        self.approvalDelay = approvalDelay
    }

    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        var pending = dto
        pending.membershipStatus = .pendingApproval
        pending.joinDate = nil
        pending.updatedAt = .now
        member = pending

        scheduleSimulatedApproval()

        return MembershipApplicationResponse(authToken: "mock-token", member: pending)
    }

    func fetchCurrentMember() async throws -> MemberDTO {
        guard let member else { throw APIClientError.notAuthenticated }
        return member
    }

    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        member = dto
        return dto
    }

    private func scheduleSimulatedApproval() {
        Task {
            try? await Task.sleep(for: approvalDelay)
            guard var current = member, current.membershipStatus == .pendingApproval else { return }
            current.membershipStatus = .active
            current.joinDate = .now
            current.updatedAt = .now
            member = current
        }
    }
}

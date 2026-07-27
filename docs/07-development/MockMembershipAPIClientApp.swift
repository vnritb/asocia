import Foundation

/// Mock de `MembershipAPIClient` para usar en modo `AppEnvironment.mock`.
/// A diferencia de `SyncTestMembershipAPIClient` (que es para tests
/// unitarios con control preciso de resultados), este simula un backend
/// funcional completo para desarrollo de UI sin servidor.
actor MockMembershipAPIClient: MembershipAPIClient {
    
    /// Instancia compartida para usar como valor por defecto en EnvironmentKey
    static let shared = MockMembershipAPIClient()
    
    /// Simula el envío de una solicitud de membresía
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        #if DEBUG
        print("🎭 [MOCK] submitMembershipApplication - \(dto.firstName) \(dto.firstSurname)")
        #endif
        
        // Simular latencia de red
        try? await Task.sleep(for: .milliseconds(500))
        
        // Crear respuesta con el miembro en estado pendingApproval
        var member = dto
        member.membershipStatus = .pendingApproval
        member.joinDate = Date()
        member.updatedAt = Date()
        
        let response = MembershipApplicationResponse(
            authToken: "mock-token-\(UUID().uuidString)",
            member: member
        )
        
        #if DEBUG
        print("   ✅ MOCK - Aplicación aceptada (token generado)")
        #endif
        
        return response
    }
    
    /// Simula obtener los datos del miembro actual
    func fetchCurrentMember() async throws -> MemberDTO {
        #if DEBUG
        print("🎭 [MOCK] fetchCurrentMember")
        #endif
        
        // Simular latencia de red
        try? await Task.sleep(for: .milliseconds(300))
        
        // Devolver un miembro de ejemplo
        let member = MemberDTO(
            id: UUID(),
            firstName: "Usuario",
            firstSurname: "Mock",
            secondSurname: "Simulado",
            email: "mock@example.com",
            secondaryEmail: "",
            mobilePhone: "600000000",
            landlinePhone: "",
            address: "Calle Mock 123",
            postalCode: "28001",
            city: "Madrid",
            province: "Madrid",
            birthDate: Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)),
            entryYear: "2020/2021",
            exitYear: "",
            promotion: "Promoción 2021",
            profession: "Desarrollador",
            workplace: "Mock Company",
            iban: "",
            facebookUsername: "",
            instagramUsername: "@mock",
            xUsername: "",
            tiktokUsername: "",
            photoBase64: nil,
            isSearchable: true,
            associationID: nil,
            isVisibleToOtherAssociations: false,
            membershipStatus: .active,
            joinDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
            rejectionReason: nil,
            updatedAt: Date()
        )
        
        #if DEBUG
        print("   ✅ MOCK - Member obtenido: \(member.firstName) \(member.firstSurname)")
        #endif
        
        return member
    }
    
    /// Simula actualizar los datos del miembro
    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        #if DEBUG
        print("🎭 [MOCK] updateMember - \(dto.firstName) \(dto.firstSurname)")
        #endif
        
        // Simular latencia de red
        try? await Task.sleep(for: .milliseconds(400))
        
        // Devolver el mismo DTO con updatedAt actualizado
        var updated = dto
        updated.updatedAt = Date()
        
        #if DEBUG
        print("   ✅ MOCK - Member actualizado")
        #endif
        
        return updated
    }
}

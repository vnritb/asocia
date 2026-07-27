import Foundation

/// Wrapper del APIClient real que añade auto-validación de altas en entorno Local.
///
/// Comportamiento especial (solo en modo Local):
/// - Después de 8 segundos de enviar una solicitud, automáticamente:
///   - Si firstName empieza con "A" → Aprobado (active)
///   - Si firstName empieza con "B" → Rechazado (rejected)
///   - Otros nombres → Sin validación automática (pendingApproval)
///
/// Esto simula el backoffice aprobando/rechazando altas sin necesidad de
/// intervención manual, útil para testing del flujo completo.
actor LocalAutoValidationAPIClient: MembershipAPIClient {
    
    private let realClient: APIClient
    private var pendingApplications: [UUID: MemberDTO] = [:]
    
    init(baseURL: URL) {
        self.realClient = APIClient(baseURL: baseURL)
    }
    
    // MARK: - MembershipAPIClient Protocol
    
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        #if DEBUG
        print("🔧 [LOCAL-AUTO] Interceptando submitMembershipApplication")
        #endif
        
        // Llamar al cliente real
        let response = try await realClient.submitMembershipApplication(dto)
        
        // Guardar la solicitud para procesarla después
        pendingApplications[dto.id] = dto
        
        // Programar auto-validación según el nombre
        scheduleAutoValidation(for: dto)
        
        return response
    }
    
    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        // Pasar al cliente real
        return try await realClient.updateMember(dto)
    }
    
    // MARK: - Auto Validation Logic
    
    private func scheduleAutoValidation(for dto: MemberDTO) {
        let firstName = dto.firstName.trimmingCharacters(in: .whitespaces)
        
        guard !firstName.isEmpty else {
            #if DEBUG
            print("⚠️ [LOCAL-AUTO] Nombre vacío, sin auto-validación")
            #endif
            return
        }
        
        // Comparación EXACTA del nombre completo
        let action: ValidationAction
        switch firstName {
        case "A":
            action = .approve
        case "B":
            action = .reject
        default:
            action = .none
        }
        
        guard action != .none else {
            #if DEBUG
            print("ℹ️ [LOCAL-AUTO] Nombre '\(firstName)' no requiere auto-validación (solo 'A' o 'B')")
            #endif
            return
        }
        
        #if DEBUG
        print("⏱️ [LOCAL-AUTO] Programada auto-validación para '\(firstName)' → \(action) en 8 segundos")
        #endif
        
        // Programar la validación en 8 segundos
        Task {
            try? await Task.sleep(for: .seconds(8))
            await performAutoValidation(memberId: dto.id, action: action, firstName: firstName)
        }
    }
    
    private func performAutoValidation(memberId: UUID, action: ValidationAction, firstName: String) async {
        guard var dto = pendingApplications[memberId] else {
            #if DEBUG
            print("⚠️ [LOCAL-AUTO] Solicitud \(memberId) ya no existe, cancelando auto-validación")
            #endif
            return
        }
        
        #if DEBUG
        switch action {
        case .approve:
            print("✅ [LOCAL-AUTO] AUTO-APROBANDO a '\(firstName)' (nombre = 'A')")
        case .reject:
            print("❌ [LOCAL-AUTO] AUTO-RECHAZANDO a '\(firstName)' (nombre = 'B')")
        case .none:
            break
        }
        #endif
        
        // Actualizar el DTO con el nuevo estado
        switch action {
        case .approve:
            dto.membershipStatus = .active
            dto.joinDate = Date()
            dto.rejectionReason = nil
        case .reject:
            dto.membershipStatus = .rejected
            dto.rejectionReason = "Auto-rechazado en modo Local (nombre = 'B')"
        case .none:
            break
        }
        dto.updatedAt = Date()
        
        // Guardar el estado actualizado
        pendingApplications[memberId] = dto
        
        #if DEBUG
        print("🔔 [LOCAL-AUTO] Estado actualizado → \(dto.membershipStatus)")
        print("   El SyncEngine lo detectará en el próximo fetchCurrentMember()")
        #endif
    }
    
    func fetchCurrentMember() async throws -> MemberDTO {
        // Primero intentar obtener del backend real
        var member = try await realClient.fetchCurrentMember()
        
        // Si hay una versión auto-validada, usar esa
        if let validatedMember = pendingApplications[member.id] {
            #if DEBUG
            print("🔄 [LOCAL-AUTO] Devolviendo versión auto-validada: \(validatedMember.membershipStatus)")
            #endif
            member = validatedMember
        }
        
        return member
    }
    
    // MARK: - Helpers
    
    private enum ValidationAction: CustomStringConvertible {
        case approve
        case reject
        case none
        
        var description: String {
            switch self {
            case .approve: return "APROBAR"
            case .reject: return "RECHAZAR"
            case .none: return "SIN ACCIÓN"
            }
        }
    }
}


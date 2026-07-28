import Foundation

/// Wrapper del APIClient real que añade auto-validación de altas en entorno Local.
///
/// Comportamiento especial (solo en modo Local):
/// - Después de 8 segundos de enviar una solicitud, automáticamente:
///   - Si firstName es exactamente "A" → Aprobado (active)
///   - Si firstName es exactamente "B" → Rechazado (rejected)
///   - Otros nombres → Sin validación automática (pendingApproval)
///
/// Esto simula el backoffice aprobando/rechazando altas sin necesidad de
/// intervención manual, útil para testing del flujo completo. A diferencia
/// de una simulación en memoria, esto llama a los mismos endpoints
/// `/v1/admin/members/:id/confirm` y `/reject` que usaría el backoffice
/// real, así que la confirmación queda persistida en la base de datos
/// (membership-service) y sobrevive a un reinicio de la app o a una sesión
/// iniciada con un token de un acceso previo.
actor LocalAutoValidationAPIClient: MembershipAPIClient {

    private let realClient: APIClient
    private let baseURL: URL
    private let adminAPIKey: String

    /// `adminAPIKey` debe coincidir con `ADMIN_API_KEY` de membership-service
    /// (ver backend/docker-compose.yml); por defecto es el mismo valor que
    /// docker-compose usa para entorno local si no se sobreescribe.
    init(
        baseURL: URL,
        adminAPIKey: String = ProcessInfo.processInfo.environment["ASOCIA_ADMIN_API_KEY"] ?? "changeme-admin-key"
    ) {
        self.realClient = APIClient(baseURL: baseURL)
        self.baseURL = baseURL
        self.adminAPIKey = adminAPIKey
    }

    // MARK: - MembershipAPIClient Protocol

    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        #if DEBUG
        print("🔧 [LOCAL-AUTO] Interceptando submitMembershipApplication")
        #endif

        let response = try await realClient.submitMembershipApplication(dto)
        scheduleAutoValidation(memberId: dto.id, firstName: dto.firstName)
        return response
    }

    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        try await realClient.updateMember(dto)
    }

    func fetchCurrentMember() async throws -> MemberDTO {
        try await realClient.fetchCurrentMember()
    }

    func checkStatus(id: UUID) async throws -> MemberStatusResponse {
        try await realClient.checkStatus(id: id)
    }

    // MARK: - Auto Validation Logic

    private func scheduleAutoValidation(memberId: UUID, firstName: String) {
        let name = firstName.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else {
            #if DEBUG
            print("⚠️ [LOCAL-AUTO] Nombre vacío, sin auto-validación")
            #endif
            return
        }

        // Comparación EXACTA del nombre completo
        let action: ValidationAction
        switch name {
        case "A":
            action = .approve
        case "B":
            action = .reject
        default:
            action = .none
        }

        guard action != .none else {
            #if DEBUG
            print("ℹ️ [LOCAL-AUTO] Nombre '\(name)' no requiere auto-validación (solo 'A' o 'B')")
            #endif
            return
        }

        #if DEBUG
        print("⏱️ [LOCAL-AUTO] Programada auto-validación para '\(name)' → \(action) en 8 segundos")
        #endif

        Task {
            try? await Task.sleep(for: .seconds(8))
            await performAutoValidation(memberId: memberId, action: action, firstName: name)
        }
    }

    /// Llama al endpoint admin real (`/confirm` o `/reject`), igual que
    /// haría el backoffice: así el `UPDATE` queda en la base de datos y no
    /// solo en memoria de este proceso.
    private func performAutoValidation(memberId: UUID, action: ValidationAction, firstName: String) async {
        let path = action == .approve ? "confirm" : "reject"
        let url = baseURL.appendingPathComponent("/v1/admin/members/\(memberId.uuidString.lowercased())/\(path)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(adminAPIKey, forHTTPHeaderField: "x-admin-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if action == .reject {
            request.httpBody = try? JSONEncoder().encode([
                "reason": "Auto-rechazado en modo Local (nombre = 'B')"
            ])
        }

        #if DEBUG
        switch action {
        case .approve:
            print("✅ [LOCAL-AUTO] AUTO-APROBANDO a '\(firstName)' (nombre = 'A') → \(url.absoluteString)")
        case .reject:
            print("❌ [LOCAL-AUTO] AUTO-RECHAZANDO a '\(firstName)' (nombre = 'B') → \(url.absoluteString)")
        case .none:
            break
        }
        #endif

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                #if DEBUG
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("⚠️ [LOCAL-AUTO] El backend rechazó la auto-validación (status \(status))")
                #endif
                return
            }
            #if DEBUG
            print("🔔 [LOCAL-AUTO] Confirmación persistida en la base de datos por membership-service")
            #endif
            _ = data
        } catch {
            #if DEBUG
            print("⚠️ [LOCAL-AUTO] No se pudo contactar con membership-service para auto-validar: \(error)")
            #endif
        }
    }

    // MARK: - Helpers

    private enum ValidationAction: CustomStringConvertible, Equatable {
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

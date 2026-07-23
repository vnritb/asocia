import Foundation

/// DTO (Data Transfer Object) que viatja per xarxa. Es manté separat del
/// `@Model` de SwiftData a propòsit: el model de persistència local pot
/// evolucionar (migracions de SwiftData) sense acoblar-se al contracte de
/// l'API del backend, i viceversa.
struct MemberDTO: Codable, Sendable {
    var id: UUID
    var firstName: String
    var firstSurname: String
    var secondSurname: String
    var email: String
    var secondaryEmail: String
    var mobilePhone: String
    var landlinePhone: String
    var address: String
    var postalCode: String
    var city: String
    var province: String
    var birthDate: Date?
    var entryYear: String
    var exitYear: String
    var promotion: String
    var profession: String
    var workplace: String
    var iban: String
    var facebookUsername: String
    var instagramUsername: String
    var xUsername: String
    var tiktokUsername: String
    /// Fotografia en base64 (JPEG). Per a un backend real es recomana pujar-la
    /// per separat a un bucket d'objectes (p.ex. Cloudflare R2/S3-compatible)
    /// i guardar aquí només la URL — veure docs/ARQUITECTURA.md.
    var photoBase64: String?
    var isSearchable: Bool
    var associationID: String?
    var isVisibleToOtherAssociations: Bool
    var membershipStatus: MembershipStatus
    var joinDate: Date?
    var rejectionReason: String?
    var updatedAt: Date
}

/// Resposta en enviar la sol·licitud d'alta.
struct MembershipApplicationResponse: Codable, Sendable {
    var authToken: String
    var member: MemberDTO
}

/// Contracte de xarxa del qual depenen `SyncEngine` i `SignupView`.
///
/// Existeix com a protocol (en comptes d'usar `APIClient` directament) per
/// poder injectar un doble de test a `AsociaTests` sense tocar la xarxa
/// real: veure `AsociaTests/SyncEngineTests.swift`.
protocol MembershipAPIClient: Sendable {
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse
    func fetchCurrentMember() async throws -> MemberDTO
    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO
}

/// Client HTTP cap a l'API Gateway del backend de microserveis.
///
/// Totes les crides són async/await sobre `URLSession`. `SyncEngine` és
/// l'únic punt que hauria de cridar aquest client; la UI mai l'usa
/// directament (sempre passa per SwiftData + SyncEngine).
actor APIClient: MembershipAPIClient {

    /// URL base del API Gateway. La decide `AppEnvironment` (mock/local/
    /// staging/producción) en el punto de creación — ver `AsociaApp.swift`.
    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?

    init(baseURL: URL = AppEnvironment.current.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.authToken = KeychainStore.loadToken()
    }

    // MARK: - Alta de soci

    /// Envia el formulari d'alta (sense pagament: l'alta queda `pendingApproval`
    /// fins que l'equip gestor la confirma manualment des del backoffice).
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        let response: MembershipApplicationResponse = try await post("/v1/members/apply", body: dto, authenticated: false)
        authToken = response.authToken
        KeychainStore.saveToken(response.authToken)
        return response
    }

    // MARK: - Sincronització

    /// Descarrega l'estat més recent del soci (usat per `SyncEngine` tant a
    /// l'arrencada com en sincronitzacions periòdiques).
    func fetchCurrentMember() async throws -> MemberDTO {
        try await get("/v1/members/me")
    }

    /// Puja canvis locals (p.ex. telèfon o adreça editats sense connexió).
    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        try await patch("/v1/members/me", body: dto)
    }

    // MARK: - HTTP helpers

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await send(path: path, method: "GET", body: Optional<Int>.none)
    }

    private func post<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body, authenticated: Bool = true
    ) async throws -> Response {
        try await send(path: path, method: "POST", body: body, authenticated: authenticated)
    }

    private func patch<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body
    ) async throws -> Response {
        try await send(path: path, method: "PATCH", body: body)
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String, method: String, body: Body?, authenticated: Bool = true
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated {
            guard let authToken else { throw APIClientError.notAuthenticated }
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let body { request.httpBody = try encoder.encode(body) }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.transport
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIClientError.server(statusCode: http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }
}

enum APIClientError: LocalizedError {
    case notAuthenticated
    case transport
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Sessió no iniciada."
        case .transport:
            return "No hi ha connexió amb el servidor."
        case .server(let statusCode):
            return "Error del servidor (\(statusCode))."
        }
    }
}

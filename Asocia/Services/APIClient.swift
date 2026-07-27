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
    
    // MARK: - Custom Decoding
    
    /// Inicializador normal para crear DTOs desde la app
    init(
        id: UUID,
        firstName: String,
        firstSurname: String,
        secondSurname: String,
        email: String,
        secondaryEmail: String,
        mobilePhone: String,
        landlinePhone: String,
        address: String,
        postalCode: String,
        city: String,
        province: String,
        birthDate: Date?,
        entryYear: String,
        exitYear: String,
        promotion: String,
        profession: String,
        workplace: String,
        iban: String,
        facebookUsername: String,
        instagramUsername: String,
        xUsername: String,
        tiktokUsername: String,
        photoBase64: String?,
        isSearchable: Bool,
        associationID: String?,
        isVisibleToOtherAssociations: Bool,
        membershipStatus: MembershipStatus,
        joinDate: Date?,
        rejectionReason: String?,
        updatedAt: Date
    ) {
        self.id = id
        self.firstName = firstName
        self.firstSurname = firstSurname
        self.secondSurname = secondSurname
        self.email = email
        self.secondaryEmail = secondaryEmail
        self.mobilePhone = mobilePhone
        self.landlinePhone = landlinePhone
        self.address = address
        self.postalCode = postalCode
        self.city = city
        self.province = province
        self.birthDate = birthDate
        self.entryYear = entryYear
        self.exitYear = exitYear
        self.promotion = promotion
        self.profession = profession
        self.workplace = workplace
        self.iban = iban
        self.facebookUsername = facebookUsername
        self.instagramUsername = instagramUsername
        self.xUsername = xUsername
        self.tiktokUsername = tiktokUsername
        self.photoBase64 = photoBase64
        self.isSearchable = isSearchable
        self.associationID = associationID
        self.isVisibleToOtherAssociations = isVisibleToOtherAssociations
        self.membershipStatus = membershipStatus
        self.joinDate = joinDate
        self.rejectionReason = rejectionReason
        self.updatedAt = updatedAt
    }
    
    /// Decodificación personalizada para manejar backends que devuelven
    /// números (0/1) en lugar de booleanos para isSearchable e isVisibleToOtherAssociations
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        firstSurname = try container.decode(String.self, forKey: .firstSurname)
        secondSurname = try container.decode(String.self, forKey: .secondSurname)
        email = try container.decode(String.self, forKey: .email)
        secondaryEmail = try container.decode(String.self, forKey: .secondaryEmail)
        mobilePhone = try container.decode(String.self, forKey: .mobilePhone)
        landlinePhone = try container.decode(String.self, forKey: .landlinePhone)
        address = try container.decode(String.self, forKey: .address)
        postalCode = try container.decode(String.self, forKey: .postalCode)
        city = try container.decode(String.self, forKey: .city)
        province = try container.decode(String.self, forKey: .province)
        birthDate = try container.decodeIfPresent(Date.self, forKey: .birthDate)
        entryYear = try container.decode(String.self, forKey: .entryYear)
        exitYear = try container.decode(String.self, forKey: .exitYear)
        promotion = try container.decode(String.self, forKey: .promotion)
        profession = try container.decode(String.self, forKey: .profession)
        workplace = try container.decode(String.self, forKey: .workplace)
        iban = try container.decode(String.self, forKey: .iban)
        facebookUsername = try container.decode(String.self, forKey: .facebookUsername)
        instagramUsername = try container.decode(String.self, forKey: .instagramUsername)
        xUsername = try container.decode(String.self, forKey: .xUsername)
        tiktokUsername = try container.decode(String.self, forKey: .tiktokUsername)
        photoBase64 = try container.decodeIfPresent(String.self, forKey: .photoBase64)
        
        // Decodificar isSearchable: puede ser Bool o Int (0/1)
        if let boolValue = try? container.decode(Bool.self, forKey: .isSearchable) {
            isSearchable = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isSearchable) {
            isSearchable = intValue != 0
        } else {
            isSearchable = false // Valor por defecto
        }
        
        associationID = try container.decodeIfPresent(String.self, forKey: .associationID)
        
        // Decodificar isVisibleToOtherAssociations: puede ser Bool o Int (0/1)
        if let boolValue = try? container.decode(Bool.self, forKey: .isVisibleToOtherAssociations) {
            isVisibleToOtherAssociations = boolValue
        } else if let intValue = try? container.decode(Int.self, forKey: .isVisibleToOtherAssociations) {
            isVisibleToOtherAssociations = intValue != 0
        } else {
            isVisibleToOtherAssociations = false // Valor por defecto
        }
        
        membershipStatus = try container.decode(MembershipStatus.self, forKey: .membershipStatus)
        joinDate = try container.decodeIfPresent(Date.self, forKey: .joinDate)
        rejectionReason = try container.decodeIfPresent(String.self, forKey: .rejectionReason)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    // MARK: - CodingKeys
    
    private enum CodingKeys: String, CodingKey {
        case id, firstName, firstSurname, secondSurname
        case email, secondaryEmail, mobilePhone, landlinePhone
        case address, postalCode, city, province
        case birthDate, entryYear, exitYear, promotion
        case profession, workplace, iban
        case facebookUsername, instagramUsername, xUsername, tiktokUsername
        case photoBase64, isSearchable, associationID, isVisibleToOtherAssociations
        case membershipStatus, joinDate, rejectionReason, updatedAt
    }
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

    init(baseURL: URL = AppEnvironment.current.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    /// Obtiene el token actual del Keychain (se recarga en cada petición)
    private var authToken: String? {
        KeychainStore.loadToken()
    }

    // MARK: - Alta de soci

    /// Envia el formulari d'alta (sense pagament: l'alta queda `pendingApproval`
    /// fins que l'equip gestor la confirma manualment des del backoffice).
    func submitMembershipApplication(_ dto: MemberDTO) async throws -> MembershipApplicationResponse {
        #if DEBUG
        print("📡 [API] submitMembershipApplication - \(dto.firstName) \(dto.firstSurname)")
        #endif
        
        let response: MembershipApplicationResponse = try await post("/v1/members/apply", body: dto, authenticated: false)
        KeychainStore.saveToken(response.authToken)
        
        #if DEBUG
        print("   ✅ Application submitted - Token saved")
        #endif
        
        return response
    }

    // MARK: - Sincronització

    /// Descarrega l'estat més recent del soci (usat per `SyncEngine` tant a
    /// l'arrencada com en sincronitzacions periòdiques).
    func fetchCurrentMember() async throws -> MemberDTO {
        #if DEBUG
        print("📡 [API] fetchCurrentMember")
        #endif
        
        let member: MemberDTO = try await get("/v1/members/me")
        
        #if DEBUG
        print("   ✅ Member fetched - Status: \(member.membershipStatus)")
        #endif
        
        return member
    }

    /// Puja canvis locals (p.ex. telèfon o adreça editats sense connexió).
    func updateMember(_ dto: MemberDTO) async throws -> MemberDTO {
        #if DEBUG
        print("📡 [API] updateMember - \(dto.firstName) \(dto.firstSurname)")
        #endif
        
        let updated: MemberDTO = try await patch("/v1/members/me", body: dto)
        
        #if DEBUG
        print("   ✅ Member updated")
        #endif
        
        return updated
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
        
        // Cargar el token al inicio de la petición
        let token = authToken
        
        #if DEBUG
        let fullURL = baseURL.appendingPathComponent(path).absoluteString
        print("   🌐 [\(method)] \(fullURL)")
        if authenticated {
            print("   🔐 Authenticated: \(token != nil ? "Yes (token presente)" : "No (sin token)")")
        }
        #endif
        
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated {
            guard let token else { 
                #if DEBUG
                print("   ❌ No auth token available in Keychain")
                #endif
                throw APIClientError.notAuthenticated 
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let body { request.httpBody = try encoder.encode(body) }

        #if DEBUG
        let startTime = Date()
        #endif
        
        let (data, response) = try await session.data(for: request)

        #if DEBUG
        let duration = Date().timeIntervalSince(startTime)
        #endif

        guard let http = response as? HTTPURLResponse else {
            #if DEBUG
            print("   ❌ Invalid HTTP response")
            #endif
            throw APIClientError.transport
        }
        
        #if DEBUG
        let emoji = (200..<300).contains(http.statusCode) ? "✅" : "❌"
        print("   \(emoji) Response: \(http.statusCode) (\(String(format: "%.0f", duration * 1000))ms)")
        #endif
        
        guard (200..<300).contains(http.statusCode) else {
            #if DEBUG
            print("   ❌ Error del servidor - Status: \(http.statusCode)")
            if let errorBody = String(data: data, encoding: .utf8) {
                print("   📄 Respuesta del servidor: \(errorBody)")
            }
            #endif
            throw APIClientError.server(statusCode: http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        #if DEBUG
        // Imprimir el JSON crudo para debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("   📥 JSON recibido: \(jsonString)")
        }
        #endif
        
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            #if DEBUG
            print("   ❌ Error decodificando JSON: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(let type, let context):
                    print("   🔴 Type mismatch - Expected: \(type)")
                    print("   🔴 Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " → "))")
                    print("   🔴 Description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("   🔴 Key '\(key.stringValue)' not found")
                    print("   🔴 Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   🔴 Value of type \(type) not found")
                    print("   🔴 Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   🔴 Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   🔴 Unknown decoding error")
                }
            }
            #endif
            throw error
        }
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

import Foundation
import CryptoKit

/// DTOs para autenticación. Coinciden con `MemberLoginRequest`/
/// `MemberLoginResponse` en `backend/packages/shared/src/types.ts`.
struct LoginRequest: Codable {
    let email: String
    let passwordHash: String
}

struct LoginResponse: Codable {
    let authToken: String
    let member: MemberDTO
}

/// Servicio de autenticación. Llama a `POST /v1/members/login` de
/// membership-service (a través del api-gateway, que ya proxea todo lo que
/// empieza por `/v1/members`) — no existe un microservicio de auth
/// independiente, así que NO usar rutas `/v1/auth/*`.
actor AuthService {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = AppEnvironment.current.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - Password Hashing
    
    /// Hash de contraseña usando SHA256 (para almacenamiento local)
    /// NOTA: El backend debería usar bcrypt, esto es solo para el cliente
    static func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Login
    
    /// Autentica un usuario con email y contraseña. Solo tiene éxito (200 +
    /// token) si las credenciales son correctas Y el alta ya está `active`
    /// — si está pendiente o rechazada, membership-service devuelve 403 y
    /// esto lanza `.pendingApproval`/`.rejected` (ver `post()` más abajo).
    func login(email: String, password: String) async throws -> LoginResponse {
        #if DEBUG
        print("🔐 [AUTH] login - email: \(email)")
        #endif

        let request = LoginRequest(email: email, passwordHash: AuthService.hashPassword(password))
        let response: LoginResponse = try await post("/v1/members/login", body: request)

        // Guardar token en Keychain
        KeychainStore.saveToken(response.authToken)

        #if DEBUG
        print("   ✅ Login exitoso - Token guardado")
        #endif

        return response
    }

    // MARK: - Logout
    
    /// Cierra sesión eliminando el token
    func logout() {
        KeychainStore.clear()
        
        #if DEBUG
        print("🚪 [AUTH] Logout - Token eliminado")
        #endif
    }
    
    // MARK: - Verificar Token
    
    /// Verifica si hay un token válido guardado
    func hasValidToken() -> Bool {
        KeychainStore.loadToken() != nil
    }
    
    // MARK: - HTTP Helpers
    
    private func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        #if DEBUG
        let startTime = Date()
        print("   🌐 [POST] \(baseURL.appendingPathComponent(path).absoluteString)")
        #endif
        
        let (data, response) = try await session.data(for: request)
        
        #if DEBUG
        let duration = Date().timeIntervalSince(startTime)
        #endif
        
        guard let http = response as? HTTPURLResponse else {
            #if DEBUG
            print("   ❌ Invalid HTTP response")
            #endif
            throw AuthServiceError.transport
        }
        
        #if DEBUG
        let emoji = (200..<300).contains(http.statusCode) ? "✅" : "❌"
        print("   \(emoji) Response: \(http.statusCode) (\(String(format: "%.0f", duration * 1000))ms)")
        #endif
        
        guard (200..<300).contains(http.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                switch errorResponse.error {
                case "invalidCredentials":
                    throw AuthServiceError.invalidCredentials
                case "pendingApproval":
                    throw AuthServiceError.pendingApproval
                case "rejected":
                    throw AuthServiceError.rejected(reason: errorResponse.rejectionReason)
                case "emailAlreadyExists":
                    throw AuthServiceError.emailAlreadyExists
                case "memberAlreadyExists":
                    throw AuthServiceError.memberAlreadyExists
                default:
                    throw AuthServiceError.server(message: errorResponse.error)
                }
            }
            throw AuthServiceError.server(message: "Error del servidor (\(http.statusCode))")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }
}

// MARK: - Errors

enum AuthServiceError: LocalizedError {
    case transport
    case server(message: String)
    case invalidCredentials
    case pendingApproval
    case rejected(reason: String?)
    case emailAlreadyExists
    case memberAlreadyExists

    var errorDescription: String? {
        switch self {
        case .transport:
            return "No hay conexión con el servidor."
        case .server(let message):
            return message
        case .invalidCredentials:
            return "Email o contraseña incorrectos."
        case .pendingApproval:
            return "Tu alta todavía está pendiente de confirmación por el equipo gestor."
        case .rejected(let reason):
            return reason ?? "Tu alta ha sido rechazada."
        case .emailAlreadyExists:
            return "Ya existe una solicitud de alta con este email."
        case .memberAlreadyExists:
            return "Ya existe una solicitud de alta para este usuario."
        }
    }
}

struct ErrorResponse: Decodable {
    let error: String
    let rejectionReason: String?
}

// MARK: - Environment Key para AuthService

import SwiftUI

struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthService = AuthService()
}

extension EnvironmentValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

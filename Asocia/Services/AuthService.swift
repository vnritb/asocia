import Foundation
import CryptoKit

/// DTOs para autenticación
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let member: MemberDTO
}

struct RegisterRequest: Codable {
    let id: UUID
    let email: String
    let password: String
    let firstName: String
    let firstSurname: String
}

/// Servicio de autenticación contra auth-service
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
    
    /// Autentica un usuario con email y contraseña
    func login(email: String, password: String) async throws -> LoginResponse {
        #if DEBUG
        print("🔐 [AUTH] login - email: \(email)")
        #endif
        
        let request = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await post("/v1/auth/login", body: request)
        
        // Guardar token en Keychain
        KeychainStore.saveToken(response.token)
        
        #if DEBUG
        print("   ✅ Login exitoso - Token guardado")
        #endif
        
        return response
    }
    
    // MARK: - Register (desde pantalla de alta)
    
    /// Registra un nuevo usuario y devuelve el token
    func register(id: UUID, email: String, password: String, firstName: String, firstSurname: String) async throws -> LoginResponse {
        #if DEBUG
        print("🔐 [AUTH] register - email: \(email)")
        #endif
        
        let request = RegisterRequest(
            id: id,
            email: email,
            password: password,
            firstName: firstName,
            firstSurname: firstSurname
        )
        let response: LoginResponse = try await post("/v1/auth/register", body: request)
        
        // Guardar token en Keychain
        KeychainStore.saveToken(response.token)
        
        #if DEBUG
        print("   ✅ Registro exitoso - Token guardado")
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
            // Intentar extraer mensaje de error del backend
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AuthServiceError.server(message: errorResponse.error)
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
    case emailAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .transport:
            return "No hay conexión con el servidor."
        case .server(let message):
            return message
        case .invalidCredentials:
            return "Email o contraseña incorrectos."
        case .emailAlreadyExists:
            return "Este email ya está registrado."
        }
    }
}

struct ErrorResponse: Decodable {
    let error: String
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

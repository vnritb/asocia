import Foundation

/// Contrato del servicio de traducción. La app nunca traduce nada
/// localmente: siempre delega en el backend (`translation-service`, ver
/// `backend/services/translation-service`), que usa un modelo de IA
/// (Claude) para traducir el diccionario base en español a cualquier
/// idioma del mundo, y cachea el resultado en Postgres para no volver a
/// traducir lo mismo dos veces (ni para este usuario ni para el resto).
protocol TranslationServicing: Sendable {
    /// Traduce el diccionario `strings` (clave -> texto en español) al
    /// idioma `languageCode` (código ISO 639-1, p.ej. "fr", "zh", "eu").
    func translate(strings: [String: String], to languageCode: String) async throws -> [String: String]
}

enum TranslationClientError: LocalizedError {
    case transport
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .transport: return "No hay conexión con el servicio de traducción."
        case .server(let statusCode): return "Error del servicio de traducción (\(statusCode))."
        }
    }
}

/// Cliente HTTP hacia `POST /v1/translate` en el API Gateway.
actor TranslationAPIClient: TranslationServicing {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = AppEnvironment.current.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func translate(strings: [String: String], to languageCode: String) async throws -> [String: String] {
        struct RequestBody: Encodable {
            var targetLanguage: String
            var strings: [String: String]
        }
        struct ResponseBody: Decodable {
            var strings: [String: String]
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/v1/translate"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(targetLanguage: languageCode, strings: strings))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TranslationClientError.transport }
        guard (200..<300).contains(http.statusCode) else { throw TranslationClientError.server(statusCode: http.statusCode) }

        return try JSONDecoder().decode(ResponseBody.self, from: data).strings
    }
}

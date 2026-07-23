import Foundation

/// Entorno de red de la app: de qué backend (o de ningún backend) obtiene
/// sus datos. Se decide UNA vez, al arrancar, y determina qué
/// implementación de cada servicio (`MembershipAPIClient`, `ChatServicing`,
/// `TranslationServicing`) se inyecta — ver `AsociaApp.swift`.
///
/// Cómo se elige (ver también README.md, sección "Ejecutar la app"):
/// - Se lee la variable de entorno `ASOCIA_ENVIRONMENT` del scheme activo.
///   `project.yml` define un scheme por entorno (Asocia (Mock), Asocia
///   (Local), Asocia (Staging), Asocia (Producción)); cámbialo desde
///   Xcode con Product > Scheme > Edit Scheme, o `xcodebuild -scheme`.
/// - Si no hay ninguna variable definida (p.ex. alguien le da a Run sin
///   tocar nada), por defecto es `.mock` en builds Debug y `.production`
///   en builds Release, para que la app nunca intente hablar por accidente
///   con un backend real desde un build de desarrollo.
enum AppEnvironment: String, CaseIterable {
    /// Sin red: todo (alta, Chat, traducción) usa datos e IA "de mentira"
    /// en memoria. Es el modo por defecto para desarrollar la UI sin
    /// depender de que el backend esté levantado.
    case mock

    /// Los 4 microservicios corriendo en local con Docker Compose
    /// (`cd backend && docker compose up`), expuestos en localhost:4000.
    case local

    /// Backend de preproducción (Render), para probar con datos reales
    /// separados de producción antes de publicar una versión.
    case staging

    /// Backend de producción real.
    case production

    static var current: AppEnvironment {
        if let raw = ProcessInfo.processInfo.environment["ASOCIA_ENVIRONMENT"],
           let value = AppEnvironment(rawValue: raw) {
            return value
        }
        #if DEBUG
        return .mock
        #else
        return .production
        #endif
    }

    /// URL base del API Gateway para este entorno. No se usa en `.mock`
    /// (ningún cliente mock llega a abrir una conexión de red).
    var apiBaseURL: URL {
        switch self {
        case .mock:
            return URL(string: "http://localhost:0")! // no se usa nunca
        case .local:
            return URL(string: "http://localhost:4000")!
        case .staging:
            // Cambia esto por la URL real del Web Service de staging en
            // cuanto lo despliegues (ver .github/workflows/deploy-staging.yml).
            return URL(string: "https://asocia-api-staging.onrender.com")!
        case .production:
            // Cambia esto por la URL real del Web Service de producción.
            return URL(string: "https://asocia-api.onrender.com")!
        }
    }

    var usesMockServices: Bool { self == .mock }

    /// Etiqueta visible solo en Ajustes (modo debug) para que quede claro
    /// contra qué entorno se está probando — evita el clásico "¿esto es
    /// producción o no?" al hacer una demo.
    var displayName: String {
        switch self {
        case .mock: return "Mock (sin red)"
        case .local: return "Local (Docker)"
        case .staging: return "Preproducción"
        case .production: return "Producción"
        }
    }
}

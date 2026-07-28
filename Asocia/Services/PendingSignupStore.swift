import Foundation

/// Recuerda, entre lanzamientos de la app, el `id` de una solicitud de alta
/// enviada desde este dispositivo mientras todavía no hay sesión (el alta
/// sigue `pendingApproval`). No es información sensible (un UUID sin más),
/// así que basta con `UserDefaults` — el token de sesión de verdad sigue
/// viviendo solo en `KeychainStore`, una vez el alta se confirma.
///
/// `RootView` lo usa para "sincronizar" en cada apertura de la app: si hay
/// un id pendiente guardado, comprueba `GET /v1/members/:id/status` y, en
/// cuanto el backoffice confirma el alta, obtiene ahí mismo el authToken
/// sin que el usuario tenga que volver a escribir sus credenciales.
enum PendingSignupStore {

    private static let key = "org.itb.asocia.pendingSignupMemberID"

    static func save(memberID: UUID) {
        UserDefaults.standard.set(memberID.uuidString, forKey: key)
    }

    static var memberID: UUID? {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }
        return UUID(uuidString: raw)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

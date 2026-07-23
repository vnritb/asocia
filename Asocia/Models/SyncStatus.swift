import Foundation

/// Estado de sincronización de un registro local frente al backend.
///
/// Esto es lo que permite que la app funcione "offline-first": siempre se
/// lee y se escribe primero en SwiftData (local), y este campo indica si
/// esos datos ya están confirmados por el servidor o si hay cambios en
/// espera de subir (o bajar) en cuanto haya conexión.
enum SyncStatus: String, Codable, Sendable {

    /// El registro local coincide con la última versión conocida del servidor.
    case synced

    /// Hay cambios locales que todavía no se han enviado al backend
    /// (p.ej. el usuario editó su teléfono sin conexión).
    case pendingUpload

    /// Se ha recibido una versión más reciente del servidor pero aún no
    /// se ha aplicado/confirmado localmente (poco habitual, útil para
    /// notificaciones push de cambio de estado de socio).
    case pendingDownload

    /// El servidor y el cliente tienen versiones distintas del mismo
    /// registro modificadas de forma independiente. Se resuelve con la
    /// política "servidor gana" salvo en el borrador de alta en curso
    /// (ver SyncEngine.resolveConflict).
    case conflict

    /// Se ha intentado sincronizar y ha fallado (sin red, o error 5xx).
    /// Se reintentará con backoff exponencial.
    case syncFailed
}

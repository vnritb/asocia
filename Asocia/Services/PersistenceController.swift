import Foundation
import SwiftData

/// Configura el `ModelContainer` de SwiftData que respalda toda la app.
///
/// SwiftData es la base de datos local (offline-first): la UI lee y escribe
/// siempre aquí primero, y `SyncEngine` sincroniza en segundo plano contra
/// el backend. Así la app funciona sin conexión y siempre muestra los
/// últimos datos descargados, marcando lo pendiente vía `SyncStatus`.
@MainActor
enum PersistenceController {

    /// Los UI tests lanzan la app con `-UITEST_RESET_STATE YES` para arrancar
    /// siempre desde "no soy socio", sin depender del estado dejado por una
    /// ejecución anterior en el simulador.
    private static var isResettingForUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITEST_RESET_STATE")
    }

    static let shared: ModelContainer = {
        let schema = Schema([Member.self])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isResettingForUITests,
            cloudKitDatabase: .none // ver docs/ARQUITECTURA.md: no usamos CloudKit
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("No se pudo crear el ModelContainer de SwiftData: \(error)")
        }
    }()

    /// Contenedor en memoria, útil para tests y para SwiftUI Previews.
    static func inMemoryContainer() -> ModelContainer {
        let schema = Schema([Member.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("No se pudo crear el ModelContainer en memoria: \(error)")
        }
    }
}

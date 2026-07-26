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
    
    /// Crea un contenedor con datos de prueba para desarrollo y testing
    @MainActor
    static func previewContainer(withSampleData: Bool = true) -> ModelContainer {
        let container = inMemoryContainer()
        
        if withSampleData {
            addSampleMembers(to: container.mainContext)
        }
        
        return container
    }
    
    /// Agrega miembros de prueba al contexto
    @MainActor
    private static func addSampleMembers(to context: ModelContext) {
        // Miembro 1: Usuario activo completo
        let member1 = Member(
            firstName: "Ana",
            firstSurname: "García",
            secondSurname: "López",
            email: "ana.garcia@example.com",
            secondaryEmail: "ana@gmail.com",
            mobilePhone: "600123456",
            landlinePhone: "912345678",
            address: "Calle Mayor 15, 3º B",
            postalCode: "28001",
            city: "Madrid",
            province: "Madrid",
            birthDate: Calendar.current.date(from: DateComponents(year: 1995, month: 3, day: 15)),
            entryYear: "2013/2014",
            exitYear: "2018/2019",
            promotion: "Promoción 2019",
            profession: "Ingeniera de Software",
            workplace: "Tech Solutions S.L.",
            iban: "ES9121000418450200051332",
            facebookUsername: "ana.garcia",
            instagramUsername: "@anagarcia",
            xUsername: "@ana_dev",
            tiktokUsername: "",
            photoData: nil,
            isSearchable: true,
            associationID: nil,
            isVisibleToOtherAssociations: false,
            membershipStatus: .active,
            joinDate: Date().addingTimeInterval(-365 * 24 * 60 * 60), // Hace 1 año
            rejectionReason: nil
        )
        member1.syncStatus = .synced
        member1.serverUpdatedAt = Date()
        context.insert(member1)
        
        #if DEBUG
        print("✅ Usuario de prueba agregado: \(member1.fullName)")
        #endif
        
        // Puedes agregar más usuarios de prueba aquí si lo necesitas
        // Por ejemplo, uno con estado pendiente:
        /*
        let member2 = Member(
            firstName: "Carlos",
            firstSurname: "Rodríguez",
            secondSurname: "Martínez",
            email: "carlos@example.com",
            secondaryEmail: "",
            mobilePhone: "655987654",
            landlinePhone: "",
            address: "Avenida de la Constitución 42",
            postalCode: "41001",
            city: "Sevilla",
            province: "Sevilla",
            birthDate: Calendar.current.date(from: DateComponents(year: 1998, month: 7, day: 22)),
            entryYear: "2016/2017",
            exitYear: "2021/2022",
            promotion: "Promoción 2022",
            profession: "Diseñador Gráfico",
            workplace: "Freelance",
            iban: "",
            facebookUsername: "",
            instagramUsername: "@carlos_design",
            xUsername: "",
            tiktokUsername: "",
            photoData: nil,
            isSearchable: true,
            associationID: nil,
            isVisibleToOtherAssociations: false,
            membershipStatus: .pendingApproval,
            joinDate: nil,
            rejectionReason: nil
        )
        member2.syncStatus = .pendingUpload
        context.insert(member2)
        
        #if DEBUG
        print("✅ Usuario de prueba agregado: \(member2.fullName)")
        #endif
        */
        
        do {
            try context.save()
            #if DEBUG
            print("💾 Datos de prueba guardados en SwiftData")
            #endif
        } catch {
            print("❌ Error guardando datos de prueba: \(error)")
        }
    }
    
    /// Carga datos de prueba en el contenedor compartido (solo para desarrollo)
    @MainActor
    static func loadSampleDataIfNeeded() {
        #if DEBUG
        // Solo cargar si no hay miembros y estamos en modo debug
        let context = shared.mainContext
        let descriptor = FetchDescriptor<Member>()
        
        do {
            let existingMembers = try context.fetch(descriptor)
            if existingMembers.isEmpty && !isResettingForUITests {
                print("📊 No hay miembros en la BD. Cargando datos de prueba...")
                addSampleMembers(to: context)
            }
        } catch {
            print("❌ Error verificando miembros existentes: \(error)")
        }
        #endif
    }
}

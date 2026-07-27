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
        do {
            let schema = Schema([Member.self])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: isResettingForUITests,
                cloudKitDatabase: .none // ver docs/ARQUITECTURA.md: no usamos CloudKit
            )

            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            #if DEBUG
            print("✅ ModelContainer creado exitosamente")
            #endif
            
            return container
        } catch {
            #if DEBUG
            print("❌ Error creando ModelContainer: \(error)")
            print("   Tipo de error: \(type(of: error))")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
            #endif
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
        let sampleMembers = [
            ("Ana", "García", "López", "ana.garcia@example.com", "Ingeniera de Software", "Tech Solutions S.L.", "Madrid", 1995, 3, 15, "2013/2014", "2018/2019", "@anagarcia", true),
            ("Carlos", "Rodríguez", "Martínez", "carlos.rodriguez@example.com", "Diseñador Gráfico", "Freelance", "Sevilla", 1998, 7, 22, "2016/2017", "2021/2022", "@carlos_design", true),
            ("María", "Fernández", "Sánchez", "maria.fernandez@example.com", "Médica", "Hospital Universitario", "Barcelona", 1993, 11, 8, "2011/2012", "2017/2018", "@mariafernandez", true),
            ("Javier", "López", "Moreno", "javier.lopez@example.com", "Abogado", "López & Asociados", "Valencia", 1990, 5, 19, "2008/2009", "2013/2014", "@javierlopez", true),
            ("Laura", "Martínez", "Ruiz", "laura.martinez@example.com", "Profesora", "IES Miguel de Cervantes", "Zaragoza", 1996, 9, 3, "2014/2015", "2019/2020", "@laura_teacher", true),
            ("David", "Sánchez", "Torres", "david.sanchez@example.com", "Arquitecto", "Sánchez Arquitectura", "Málaga", 1992, 12, 27, "2010/2011", "2016/2017", "@davidsanchez", true),
            ("Elena", "Pérez", "Ramírez", "elena.perez@example.com", "Periodista", "El Mundo Digital", "Bilbao", 1994, 2, 14, "2012/2013", "2017/2018", "@elenaperez", true),
            ("Pablo", "Gómez", "Navarro", "pablo.gomez@example.com", "Ingeniero Civil", "Constructora ABC", "Alicante", 1991, 8, 6, "2009/2010", "2015/2016", "@pablogomez", true),
            ("Sara", "Díaz", "Romero", "sara.diaz@example.com", "Marketing Manager", "Digital Marketing Pro", "Granada", 1997, 4, 25, "2015/2016", "2020/2021", "@saradiaz", true),
            ("Miguel", "Ruiz", "Jiménez", "miguel.ruiz@example.com", "Fisioterapeuta", "Centro Médico Ruiz", "Murcia", 1989, 10, 11, "2007/2008", "2013/2014", "@miguelruiz", true),
            ("Lucía", "Hernández", "Gil", "lucia.hernandez@example.com", "Chef", "Restaurante La Estrella", "Pamplona", 1999, 6, 30, "2017/2018", "2022/2023", "@lucia_chef", true),
            ("Adrián", "Moreno", "Vázquez", "adrian.moreno@example.com", "Fotógrafo", "Moreno Photography", "Salamanca", 1988, 1, 17, "2006/2007", "2011/2012", "@adrianmoreno", true),
            ("Carmen", "Álvarez", "Castro", "carmen.alvarez@example.com", "Psicóloga", "Centro Psicológico Álvarez", "Córdoba", 2000, 7, 9, "2018/2019", "2023/2024", "@carmenalvarez", true),
            ("Sergio", "Romero", "Ortega", "sergio.romero@example.com", "Veterinario", "Clínica Veterinaria San Juan", "Toledo", 1995, 3, 21, "2013/2014", "2019/2020", "@sergiovet", true),
            ("Natalia", "Torres", "Rubio", "natalia.torres@example.com", "Farmacéutica", "Farmacia Torres", "Valladolid", 1993, 11, 4, "2011/2012", "2017/2018", "@nataliatorres", true),
            ("Rubén", "Jiménez", "Marín", "ruben.jimenez@example.com", "Programador", "StartUp Tech", "Santander", 1998, 5, 18, "2016/2017", "2021/2022", "@rubendev", true),
            ("Isabel", "Gil", "Suárez", "isabel.gil@example.com", "Traductora", "Freelance", "León", 1992, 9, 12, "2010/2011", "2015/2016", "@isabelgil", true),
            ("Raúl", "Vargas", "Mendoza", "raul.vargas@example.com", "Contador", "Vargas Consulting", "Logroño", 1987, 12, 28, "2005/2006", "2011/2012", "@raulvargas", true),
            ("Cristina", "Molina", "Herrera", "cristina.molina@example.com", "Enfermera", "Hospital General", "Cáceres", 1996, 2, 7, "2014/2015", "2019/2020", "@cristinamolina", true),
            ("Alberto", "Castro", "Domínguez", "alberto.castro@example.com", "Músico", "Orquesta Sinfónica", "Oviedo", 1990, 4, 16, "2008/2009", "2014/2015", "@albertocastro", true)
        ]
        
        #if DEBUG
        print("📊 Creando 20 usuarios de prueba para el chat...")
        #endif
        
        for (index, data) in sampleMembers.enumerated() {
            let (firstName, firstSurname, secondSurname, email, profession, workplace, city, birthYear, birthMonth, birthDay, entryYear, exitYear, instagram, isSearchable) = data
            
            let member = Member(
                firstName: firstName,
                firstSurname: firstSurname,
                secondSurname: secondSurname,
                email: email,
                secondaryEmail: "\(firstName.lowercased())@gmail.com",
                mobilePhone: "6\(String(format: "%08d", 100000000 + index * 10000000))",
                landlinePhone: index % 3 == 0 ? "9\(String(format: "%08d", 10000000 + index * 1000000))" : "",
                address: "Calle \(["Mayor", "Principal", "Real", "Sol", "Luna", "Estrella"][index % 6]) \(index + 1), \(index % 5 + 1)º \(["A", "B", "C", "D"][index % 4])",
                postalCode: String(format: "%05d", 28001 + index * 100),
                city: city,
                province: city,
                birthDate: Calendar.current.date(from: DateComponents(year: birthYear, month: birthMonth, day: birthDay)),
                entryYear: entryYear,
                exitYear: exitYear,
                promotion: "Promoción \(exitYear.split(separator: "/").last ?? "")",
                profession: profession,
                workplace: workplace,
                iban: index % 2 == 0 ? "ES\(String(format: "%022d", 912108450200051332 + index))" : "",
                facebookUsername: index % 4 == 0 ? "\(firstName.lowercased()).\(firstSurname.lowercased())" : "",
                instagramUsername: instagram,
                xUsername: index % 3 == 0 ? "@\(firstName.lowercased())_\(firstSurname.lowercased())" : "",
                tiktokUsername: index % 5 == 0 ? "@\(firstName.lowercased())\(birthYear)" : "",
                photoData: nil,
                isSearchable: isSearchable,
                associationID: nil,
                isVisibleToOtherAssociations: false,
                membershipStatus: .active,
                joinDate: Date().addingTimeInterval(-Double(365 * (1 + index)) * 24 * 60 * 60), // Diferentes antigüedades
                rejectionReason: nil
            )
            member.syncStatus = .synced
            member.serverUpdatedAt = Date()
            context.insert(member)
            
            #if DEBUG
            print("  ✅ Usuario \(index + 1)/20: \(member.fullName) - \(profession)")
            #endif
        }
        
        do {
            try context.save()
            #if DEBUG
            print("💾 20 usuarios de prueba guardados en SwiftData")
            #endif
        } catch {
            print("❌ Error guardando datos de prueba: \(error)")
        }
    }
    
    /// Carga datos de prueba en el contenedor compartido (solo para desarrollo)
    @MainActor
    static func loadSampleDataIfNeeded() {
        #if DEBUG
        // DESACTIVADO: No cargar datos de prueba automáticamente
        // Los datos de prueba solo se cargan en Previews cuando sea necesario
        print("ℹ️ loadSampleDataIfNeeded: Datos de prueba desactivados")
        #endif
    }
}

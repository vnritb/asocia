import SwiftUI
import SwiftData

@main
struct AsociaApp: App {

    let modelContainer: ModelContainer

    private let environment: AppEnvironment
    private let apiClient: MembershipAPIClient
    private let chatService: ChatServicing
    private let authService: AuthService

    @State private var localizationManager = LocalizationManager()
    @State private var syncEngine: SyncEngine?
    @State private var showSplash = true

    /// Elige la implementación real o mock de cada servicio según
    /// `AppEnvironment.current` (variable de entorno `ASOCIA_ENVIRONMENT`
    /// del scheme activo — ver `project.yml` y `AppEnvironment.swift`).
    /// Es el ÚNICO sitio del proyecto donde se decide esto: el resto de la
    /// app solo conoce los protocolos (`MembershipAPIClient`,
    /// `ChatServicing`), nunca la implementación.
    init() {
        // Limpiar datos persistentes y usar contenedor en memoria si se ejecutan UI tests
        #if DEBUG
        let isUITesting = CommandLine.arguments.contains("-UITEST_RESET_STATE")
        if isUITesting {
            // Solo aquí tiene sentido empezar de cero: los UI tests necesitan
            // arrancar siempre desde "no soy socio". Si esto se ejecutara en
            // cada lanzamiento normal en DEBUG, borraría el Member local en
            // cada relanzamiento aunque el token del Keychain siguiera siendo
            // válido, y RootView acabaría mostrando Login sin motivo.
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            print("🧪 UI Test mode: Usando contenedor en memoria y limpiando UserDefaults...")
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            self.modelContainer = PersistenceController.inMemoryContainer()
            
            // Configurar idioma para UI tests si se especifica
            if let languageIndex = CommandLine.arguments.firstIndex(of: "-UITEST_LANGUAGE"),
               languageIndex + 1 < CommandLine.arguments.count {
                let language = CommandLine.arguments[languageIndex + 1]
                UserDefaults.standard.set(language, forKey: "AppLanguage")
                print("🧪 UI Test: Idioma configurado a '\(language)'")
            }
        } else {
            self.modelContainer = PersistenceController.shared
        }
        #else
        self.modelContainer = PersistenceController.shared
        #endif
        
        let env = AppEnvironment.current
        environment = env

        let apiClient: MembershipAPIClient
        let chatService: ChatServicing

        if env.usesMockServices {
            apiClient = MockMembershipAPIClient.shared
            chatService = MockChatService()
        } else {
            // En modo Local, usar wrapper con auto-validación
            if env == .local {
                apiClient = LocalAutoValidationAPIClient(baseURL: env.apiBaseURL)
            } else {
                apiClient = APIClient(baseURL: env.apiBaseURL)
            }
            chatService = ChatAPIClient(baseURL: env.apiBaseURL)
        }

        self.apiClient = apiClient
        self.chatService = chatService
        self.authService = AuthService(baseURL: env.apiBaseURL)

        #if DEBUG
        print("🌍 Asocia arrancada en entorno: \(env.displayName) (\(env.rawValue))")
        print("🌐 API Base URL: \(env.apiBaseURL.absoluteString)")
        if env.usesMockServices {
            print("✅ Usando servicios MOCK (sin red)")
        } else {
            print("⚠️  Usando servicios REALES - El backend debe estar corriendo")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(localizationManager)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .task {
                #if DEBUG
                print("🚀 AsociaApp.task iniciado")
                let isUITesting = CommandLine.arguments.contains("-UITEST_RESET_STATE")
                
                // Cargar datos de prueba si es necesario (solo en modo debug, no en UI tests)
                if !isUITesting {
                    PersistenceController.loadSampleDataIfNeeded()
                }
                #endif
                
                // El SyncEngine necesita el ModelContext, que solo está
                // disponible una vez el WindowGroup ha inyectado el
                // modelContainer en el entorno.
                if syncEngine == nil {
                    let context = modelContainer.mainContext
                    let engine = SyncEngine(apiClient: apiClient, modelContext: context)
                    engine.start()
                    syncEngine = engine
                    #if DEBUG
                    print("   SyncEngine inicializado")
                    #endif
                }

                #if DEBUG
                if isUITesting {
                    print("   🧪 UI Test mode: Sin splash")
                    showSplash = false
                } else {
                    print("   Esperando 1.2s para ocultar splash...")
                    try? await Task.sleep(for: .seconds(1.2))
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                        print("   ✅ Splash oculto, mostrando RootView")
                    }
                }
                #else
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
                #endif
            }
            .environment(\.syncEngine, syncEngine)
            .environment(\.apiClient, apiClient)
            .environment(\.chatService, chatService)
            .environment(\.authService, authService)
            .environment(\.appEnvironment, environment)
        }
        .modelContainer(modelContainer)
    }
}

// Petites claus d'entorn per injectar dependències que no són `@Observable`
// (SyncEngine es crea de forma asíncrona perquè depèn del ModelContext;
// APIClient i ChatAPIClient/MockChatService són `actor`s, que no poden
// adoptar `@Observable`).
private struct SyncEngineKey: EnvironmentKey {
    static let defaultValue: SyncEngine? = nil
}

private struct APIClientKey: EnvironmentKey {
    static let defaultValue: MembershipAPIClient = MockMembershipAPIClient.shared
}

private struct ChatServiceKey: EnvironmentKey {
    static let defaultValue: ChatServicing = MockChatService()
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .mock
}

extension EnvironmentValues {
    var syncEngine: SyncEngine? {
        get { self[SyncEngineKey.self] }
        set { self[SyncEngineKey.self] = newValue }
    }

    var apiClient: MembershipAPIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }

    var chatService: ChatServicing {
        get { self[ChatServiceKey.self] }
        set { self[ChatServiceKey.self] = newValue }
    }

    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

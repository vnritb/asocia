import SwiftUI
import SwiftData

@main
struct AsociaApp: App {

    let modelContainer = PersistenceController.shared

    private let environment: AppEnvironment
    private let apiClient: MembershipAPIClient
    private let chatService: ChatServicing
    private let translationClient: TranslationServicing

    @State private var localizationManager: LocalizationManager
    @State private var syncEngine: SyncEngine?
    @State private var showSplash = true

    /// Elige la implementación real o mock de cada servicio según
    /// `AppEnvironment.current` (variable de entorno `ASOCIA_ENVIRONMENT`
    /// del scheme activo — ver `project.yml` y `AppEnvironment.swift`).
    /// Es el ÚNICO sitio del proyecto donde se decide esto: el resto de la
    /// app solo conoce los protocolos (`MembershipAPIClient`,
    /// `ChatServicing`, `TranslationServicing`), nunca la implementación.
    init() {
        let env = AppEnvironment.current
        environment = env

        let apiClient: MembershipAPIClient
        let chatService: ChatServicing
        let translationClient: TranslationServicing

        if env.usesMockServices {
            apiClient = MockMembershipAPIClient()
            chatService = MockChatService()
            translationClient = MockTranslationClient()
        } else {
            apiClient = APIClient(baseURL: env.apiBaseURL)
            chatService = ChatAPIClient(baseURL: env.apiBaseURL)
            translationClient = TranslationAPIClient(baseURL: env.apiBaseURL)
        }

        self.apiClient = apiClient
        self.chatService = chatService
        self.translationClient = translationClient
        _localizationManager = State(initialValue: LocalizationManager(translationClient: translationClient))

        #if DEBUG
        print("Asocia arrancada en entorno: \(env.displayName) (\(env.rawValue))")
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
                print("🚀 AsociaApp.task iniciado")
                // El SyncEngine necesita el ModelContext, que solo está
                // disponible una vez el WindowGroup ha inyectado el
                // modelContainer en el entorno.
                if syncEngine == nil {
                    let context = modelContainer.mainContext
                    let engine = SyncEngine(apiClient: apiClient, modelContext: context)
                    engine.start()
                    syncEngine = engine
                    print("   SyncEngine inicializado")
                }

                print("   Esperando 1.2s para ocultar splash...")
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                    print("   ✅ Splash oculto, mostrando RootView")
                }
            }
            .environment(\.syncEngine, syncEngine)
            .environment(\.apiClient, apiClient)
            .environment(\.chatService, chatService)
            .environment(\.appEnvironment, environment)
        }
        .modelContainer(modelContainer)
    }
}

// Petites claus d'entorn per injectar dependències que no són `@Observable`
// (SyncEngine es crea de forma asíncrona perquè depèn del ModelContext;
// APIClient, ChatAPIClient/MockChatService i TranslationAPIClient són
// `actor`s, que no poden adoptar `@Observable`).
private struct SyncEngineKey: EnvironmentKey {
    static let defaultValue: SyncEngine? = nil
}

private struct APIClientKey: EnvironmentKey {
    static let defaultValue: MembershipAPIClient = MockMembershipAPIClient()
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

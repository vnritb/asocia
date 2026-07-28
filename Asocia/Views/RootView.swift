import SwiftUI
import SwiftData

/// Punto de entrada tras el splash: decide qué pantalla mostrar según si
/// hay token válido y existe un `Member` local.
///
/// Flujo:
/// 1. Sin token → LoginView
/// 2. Con token pero sin Member → LoginView (token inválido/expirado)
/// 3. Con token y Member → MainTabView o MemberProfileView según estado
struct RootView: View {
    @Query private var members: [Member]
    @Environment(\.authService) private var authService
    @Environment(\.apiClient) private var apiClient
    @Environment(\.modelContext) private var modelContext

    @State private var isCheckingAuth = true
    @State private var hasValidAuth = false
    @State private var hasPendingSignup = false
    @State private var pollTask: Task<Void, Never>?

    private var currentMember: Member? { members.first }

    var body: some View {
        Group {
            if isCheckingAuth {
                // Verificando autenticación
                ProgressView("Cargando...")
            } else if !hasValidAuth {
                // Sin token: mientras el alta no esté confirmada, el único
                // sitio al que se tiene acceso es Login (que a su vez da
                // paso a "Crear Cuenta"). Si hay una solicitud pendiente de
                // este dispositivo, se lo indicamos para que sepa que puede
                // limitarse a esperar/reintentar en vez de darse de alta otra vez.
                LoginView(onLoginSuccess: {
                    checkAuth()
                }, hasPendingSignup: hasPendingSignup)
            } else if let member = currentMember {
                // Autenticado y con miembro
                if member.membershipStatus.hasChatAccess {
                    MainTabView(member: member)
                } else {
                    MemberProfileView(member: member)
                }
            } else {
                // Token válido pero todavía sin ficha local descargada
                // (primer arranque en este dispositivo, o caché vacía):
                // checkAuthentication() ya ha intentado traerla; si seguimos
                // aquí es que la petición falló (sin red) y toca esperar al
                // reintento de SyncEngine, no mandar al usuario a Login.
                ProgressView("Sincronizando...")
            }
        }
        .animation(.default, value: hasValidAuth)
        .animation(.default, value: currentMember?.membershipStatus)
        .task {
            await checkAuthentication()
        }
        .onDisappear {
            pollTask?.cancel()
        }
    }

    private func checkAuthentication() async {
        hasValidAuth = await authService.hasValidToken()

        // Sin token, pero hay una alta enviada desde este dispositivo que
        // podría haberse confirmado ya: lo comprobamos sin pedir nada al
        // usuario ("sincronizar"). Si ya está active, esto nos entrega el
        // authToken igual que haría un login manual.
        if !hasValidAuth, let pendingID = PendingSignupStore.memberID {
            hasPendingSignup = true
            await adoptIfConfirmed(pendingID: pendingID)
            if !hasValidAuth {
                startPollingPendingSignup()
            }
        }

        // Con token pero sin ficha local (primer arranque en este
        // dispositivo, o caché vacía): la traemos del backend antes de
        // decidir qué pantalla mostrar, para no acabar nunca en Login
        // teniendo ya una sesión válida.
        if hasValidAuth, currentMember == nil {
            do {
                let remote = try await apiClient.fetchCurrentMember()
                modelContext.insert(remote.toMember())
                try? modelContext.save()
            } catch APIClientError.notAuthenticated {
                // El token que había en Keychain ya no es válido en el
                // backend (revocado, etc.): aquí sí toca volver a Login.
                await authService.logout()
                hasValidAuth = false
            } catch {
                // Sin red u otro error transitorio: dejamos hasValidAuth a
                // true y mostramos el spinner; SyncEngine reintentará.
            }
        }

        #if DEBUG
        print("✅ RootView - Verificación de autenticación")
        print("   Token válido: \(hasValidAuth)")
        print("   Miembros encontrados: \(members.count)")
        if let member = currentMember {
            print("   Estado del miembro: \(member.membershipStatus)")
        }
        #endif

        isCheckingAuth = false
    }

    /// Comprueba `GET /v1/members/:id/status` (sin token) y, si el alta ya
    /// está `active`, adopta el `authToken` y el `Member` recibidos —
    /// exactamente igual que haría un login manual, pero sin pedir nada al
    /// usuario.
    private func adoptIfConfirmed(pendingID: UUID) async {
        if let status = try? await apiClient.checkStatus(id: pendingID),
           status.membershipStatus == .active,
           let token = status.authToken,
           let memberDTO = status.member {
            KeychainStore.saveToken(token)
            modelContext.insert(memberDTO.toMember())
            try? modelContext.save()
            PendingSignupStore.clear()
            hasPendingSignup = false
            hasValidAuth = true
        }
    }

    /// Reintenta `adoptIfConfirmed` cada pocos segundos mientras el usuario
    /// esté en Login o en el formulario de alta (las dos únicas pantallas a
    /// las que tiene acceso sin token): así, en cuanto el equipo gestor
    /// confirme el alta, la app pasa directamente al resto de contenidos sin
    /// que el usuario tenga que volver a intentar el login.
    private func startPollingPendingSignup() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled && !hasValidAuth {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                guard let pendingID = PendingSignupStore.memberID else {
                    hasPendingSignup = false
                    return
                }
                await adoptIfConfirmed(pendingID: pendingID)
            }
        }
    }

    /// Se llama al volver de Login (login manual) o del formulario de alta
    /// (nueva solicitud enviada): recalcula tanto el token como si hay una
    /// alta pendiente de este dispositivo, y reactiva el sondeo en segundo
    /// plano si procede.
    private func checkAuth() {
        Task {
            hasValidAuth = await authService.hasValidToken()
            if hasValidAuth {
                hasPendingSignup = false
                pollTask?.cancel()
            } else {
                hasPendingSignup = PendingSignupStore.memberID != nil
                if hasPendingSignup {
                    startPollingPendingSignup()
                }
            }
        }
    }
}

/// Navegación principal una vez el alta está confirmada: ficha + Chat + Ajustes.
private struct MainTabView: View {
    let member: Member

    @Environment(LocalizationManager.self) private var loc

    var body: some View {
        TabView {
            MemberProfileView(member: member)
                .tabItem { Label(loc.t("tab.profile"), systemImage: "person.crop.circle") }

            ChatListView(member: member)
                .tabItem { Label(loc.t("tab.chat"), systemImage: "bubble.left.and.bubble.right") }

            SettingsView()
                .tabItem { Label(loc.t("tab.settings"), systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .environment(LocalizationManager())
        .environment(\.authService, AuthService())
        .modelContainer(PersistenceController.inMemoryContainer())
}

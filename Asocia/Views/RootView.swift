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
    
    @State private var isCheckingAuth = true
    @State private var hasValidAuth = false

    private var currentMember: Member? { members.first }

    var body: some View {
        Group {
            if isCheckingAuth {
                // Verificando autenticación
                ProgressView("Cargando...")
            } else if !hasValidAuth {
                // Sin autenticación → Mostrar Login
                LoginView {
                    // Al hacer login exitoso, actualizar estado
                    checkAuth()
                }
            } else if let member = currentMember {
                // Autenticado y con miembro
                if member.membershipStatus.hasChatAccess {
                    MainTabView(member: member)
                } else {
                    MemberProfileView(member: member)
                }
            } else {
                // Autenticado pero sin miembro (no debería pasar)
                LoginView {
                    checkAuth()
                }
            }
        }
        .animation(.default, value: hasValidAuth)
        .animation(.default, value: currentMember?.membershipStatus)
        .task {
            await checkAuthentication()
        }
    }
    
    private func checkAuthentication() async {
        // Verificar si hay token válido
        hasValidAuth = await authService.hasValidToken()
        
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
    
    private func checkAuth() {
        Task {
            hasValidAuth = await authService.hasValidToken()
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

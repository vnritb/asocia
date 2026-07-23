import SwiftUI
import SwiftData

/// Punto de entrada tras el splash: decide qué pantalla mostrar según si
/// existe un `Member` local y su `membershipStatus`.
///
/// - Sin `Member`: botón "Asocia" a pantalla completa.
/// - `Member` con alta pendiente o rechazada: solo la ficha (sin Chat).
/// - `Member` con alta confirmada (`active`): ficha + Chat + Ajustes, en un `TabView`.
struct RootView: View {
    @Query private var members: [Member]

    private var currentMember: Member? { members.first }

    var body: some View {
        Group {
            if let member = currentMember, member.membershipStatus.showsMemberScreen {
                if member.membershipStatus.hasChatAccess {
                    MainTabView(member: member)
                } else {
                    MemberProfileView(member: member)
                }
            } else {
                MembershipButtonView()
            }
        }
        .animation(.default, value: currentMember?.membershipStatus)
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
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
        .modelContainer(PersistenceController.inMemoryContainer())
}

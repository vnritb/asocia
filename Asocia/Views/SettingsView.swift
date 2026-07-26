import SwiftUI
import SwiftData

/// Pantalla de Ajustes. De momento solo tiene el selector de idioma, pero
/// es el sitio natural donde añadir más preferencias en el futuro.
struct SettingsView: View {
    @Environment(\.appEnvironment) private var appEnvironment
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    
    @Query private var members: [Member]

    @State private var languages = WorldLanguages.all()
    @State private var showConfirmationAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                #if DEBUG
                // Visible solo en builds Debug: ayuda a no confundir contra
                // qué entorno se está probando (mock/local/staging/producción).
                Section {
                    LabeledContent("Entorno", value: appEnvironment.displayName)
                }
                
                // Sección especial para modo MOCK: permite simular la aprobación
                // de altas sin necesitar el backoffice real
                if appEnvironment.usesMockServices {
                    mockMembershipApprovalSection
                }
                #endif

                Section() {
                    Picker(loc.t("settings.language.current"), selection: languageBinding) {
                        ForEach(languages) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } footer: {
                    Text(loc.t("settings.language.footer"))
                }
            }
            .navigationTitle(loc.t("settings.navTitle"))
            .alert("Alta Confirmada", isPresented: $showConfirmationAlert) {
                Button(loc.t("common.ok")) {
                    showConfirmationAlert = false
                }
            } message: {
                Text("El alta ha sido confirmada. El usuario ahora tiene estado 'active' y acceso completo a la aplicación.")
            }
        }
    }
    
    @ViewBuilder
    private var mockMembershipApprovalSection: some View {
        if let currentMember = members.first {
            Section {
                LabeledContent("Estado actual", value: membershipStatusText(currentMember.membershipStatus))
                
                if currentMember.membershipStatus == .pendingApproval {
                    Button {
                        approveMembership(for: currentMember)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Confirmar Alta")
                        }
                    }
                    
                    Button(role: .destructive) {
                        rejectMembership(for: currentMember)
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Rechazar Alta")
                        }
                    }
                } else if currentMember.membershipStatus == .active {
                    Label("Usuario ya confirmado", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else if currentMember.membershipStatus == .rejected {
                    Label("Alta rechazada", systemImage: "xmark.seal.fill")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("🧪 Simulación de Alta (Solo Modo Mock)")
            } footer: {
                Text("En modo mock puedes simular la aprobación/rechazo de altas que normalmente haría el backoffice.")
            }
        }
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { loc.currentLanguageCode },
            set: { newCode in loc.setLanguage(newCode) }
        )
    }
    
    // MARK: - Mock Membership Helpers
    
    private func membershipStatusText(_ status: MembershipStatus) -> String {
        switch status {
        case .notMember:
            return "Sin solicitud"
        case .pendingApproval:
            return "⏳ Pendiente de aprobación"
        case .active:
            return "✅ Activo"
        case .rejected:
            return "❌ Rechazado"
        }
    }
    
    private func approveMembership(for member: Member) {
        member.membershipStatus = .active
        member.joinDate = .now
        member.rejectionReason = nil
        
        do {
            try modelContext.save()
            showConfirmationAlert = true
        } catch {
            print("Error al confirmar alta: \(error)")
        }
    }
    
    private func rejectMembership(for member: Member) {
        member.membershipStatus = .rejected
        member.rejectionReason = "Rechazado desde el simulador de altas en modo mock"
        
        do {
            try modelContext.save()
        } catch {
            print("Error al rechazar alta: \(error)")
        }
    }
}

#Preview("Settings - Mock con Usuario Pendiente") {
    let container = PersistenceController.inMemoryContainer()
    let member = Member(
        firstName: "Ana", 
        firstSurname: "García",
        email: "ana@example.com",
        mobilePhone: "600123456",
        address: "Carrer Major 1",
        postalCode: "08001",
        city: "Barcelona",
        province: "Barcelona",
        membershipStatus: .pendingApproval
    )
    container.mainContext.insert(member)
    
    return SettingsView()
        .environment(\.appEnvironment, .mock)
        .environment(LocalizationManager())
        .modelContainer(container)
}

#Preview("Settings - Sin Usuario") {
    SettingsView()
        .environment(\.appEnvironment, .mock)
        .environment(LocalizationManager())
        .modelContainer(PersistenceController.inMemoryContainer())
}

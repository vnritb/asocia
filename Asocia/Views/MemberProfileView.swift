import SwiftUI
import SwiftData

/// Pantalla de visualización y gestión de los datos personales del socio.
///
/// Se muestra en cuanto hay un `Member` local (aunque su alta todavía esté
/// `pendingApproval`: así el usuario ve de inmediato que su solicitud se ha
/// registrado, con un indicador provisional). Cuando el equipo gestor
/// confirma el alta desde el backoffice, `SyncEngine` descarga el nuevo
/// `membershipStatus == .active` y este indicador desaparece solo.
struct MemberProfileView: View {
    @Bindable var member: Member

    @Environment(\.syncEngine) private var syncEngine
    @Environment(\.modelContext) private var modelContext
    @Environment(LocalizationManager.self) private var loc
    @State private var isEditing = false
    @State private var showSettings = false
    @State private var showDiscardConfirmation = false
    /// Copia de los campos editables tomada al entrar en modo edición, para
    /// poder restaurarlos si el usuario cancela (`member` está enlazado
    /// directamente al formulario, así que los campos se modifican en vivo
    /// mientras se escribe, no solo al guardar).
    @State private var editSnapshot: MemberEditSnapshot?

    var body: some View {
        NavigationStack {
            Form {
                header

                statusSection

                Section(loc.t("profile.section.personalData")) {
                    LabeledField(label: loc.t("profile.field.name"), text: $member.firstName, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.firstSurname"), text: $member.firstSurname, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.secondSurname"), text: $member.secondSurname, isEditing: isEditing)
                }

                Section(loc.t("profile.section.contact")) {
                    LabeledField(label: loc.t("profile.field.email"), text: $member.email, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.email2"), text: $member.secondaryEmail, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.mobilePhone"), text: $member.mobilePhone, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.landlinePhone"), text: $member.landlinePhone, isEditing: isEditing)
                }

                Section(loc.t("profile.section.address")) {
                    LabeledField(label: loc.t("profile.field.address"), text: $member.address, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.postalCode"), text: $member.postalCode, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.city"), text: $member.city, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.province"), text: $member.province, isEditing: isEditing)
                }

                Section(loc.t("profile.section.academic")) {
                    LabeledField(label: loc.t("profile.field.entryYear"), text: $member.entryYear, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.exitYear"), text: $member.exitYear, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.promotion"), text: $member.promotion, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.profession"), text: $member.profession, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.workplace"), text: $member.workplace, isEditing: isEditing)
                }

                Section(loc.t("profile.section.bank")) {
                    LabeledField(label: loc.t("profile.field.iban"), text: $member.iban, isEditing: isEditing)
                }

                Section(loc.t("profile.section.social")) {
                    LabeledField(label: loc.t("profile.field.facebook"), text: $member.facebookUsername, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.instagram"), text: $member.instagramUsername, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.x"), text: $member.xUsername, isEditing: isEditing)
                    LabeledField(label: loc.t("profile.field.tiktok"), text: $member.tiktokUsername, isEditing: isEditing)
                }

                Section {
                    if isEditing {
                        Toggle(loc.t("profile.field.isSearchable"), isOn: $member.isSearchable)
                    } else {
                        LabeledContent(loc.t("profile.field.isSearchable"), value: member.isSearchable ? loc.t("common.yes") : loc.t("common.no"))
                    }
                } footer: {
                    Text(loc.t("signup.searchableFooter"))
                }

                if !isEditing {
                    Section(loc.t("profile.section.sync")) {
                        HStack {
                            Text(loc.t("profile.sync.status"))
                            Spacer()
                            Text(syncStatusLabel)
                                .foregroundStyle(.secondary)
                        }
                        if let lastSynced = syncEngine?.lastSyncedAt {
                            HStack {
                                Text(loc.t("profile.sync.lastSync"))
                                Spacer()
                                Text(lastSynced, style: .relative)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button(loc.t("profile.sync.now")) {
                            Task { await syncEngine?.syncNow() }
                        }
                        .disabled(syncEngine?.isSyncing ?? true)
                        .accessibilityIdentifier("profile_syncNowButton")
                    }
                }
            }
            .navigationTitle(loc.t("profile.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Solo hace falta este acceso directo a Ajustes cuando la
                    // ficha se muestra sola (alta pendiente/rechazada, sin
                    // TabView todavía); una vez activo, Ajustes ya es una pestaña.
                    if !member.membershipStatus.hasChatAccess {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityIdentifier("profile_settingsButton")
                        .accessibilityLabel("Ajustes")
                    }
                }
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(loc.t("common.cancel")) {
                            showDiscardConfirmation = true
                        }
                        .accessibilityIdentifier("profile_cancelButton")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? loc.t("common.save") : loc.t("common.edit")) {
                        if isEditing {
                            saveChanges()
                            isEditing = false
                            editSnapshot = nil
                        } else {
                            editSnapshot = MemberEditSnapshot(member: member)
                            isEditing = true
                        }
                    }
                    .accessibilityIdentifier("profile_editButton")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert(loc.t("profile.cancelEdit.title"), isPresented: $showDiscardConfirmation) {
                Button(loc.t("profile.cancelEdit.discard"), role: .destructive) {
                    editSnapshot?.apply(to: member)
                    editSnapshot = nil
                    isEditing = false
                }
                Button(loc.t("profile.cancelEdit.keepEditing"), role: .cancel) {}
            } message: {
                Text(loc.t("profile.cancelEdit.message"))
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            if isEditing {
                MemberPhotoPicker(photoData: $member.photoData)
            } else {
                avatarView
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let data = member.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color(.systemGray5))
                    Text(String(member.fullName.prefix(1)))
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var statusSection: some View {
        switch member.membershipStatus {
        case .pendingApproval:
            Section {
                Label(loc.t("profile.pendingApproval"), systemImage: "clock")
                    .foregroundStyle(.orange)
            }
        case .rejected:
            Section {
                Label(member.rejectionReason ?? loc.t("profile.rejected"), systemImage: "xmark.octagon")
                    .foregroundStyle(.red)
            }
        case .active:
            EmptyView() // Un cop confirmada l'alta, l'indicador provisional desapareix.
        case .notMember:
            EmptyView()
        }
    }

    private var syncStatusLabel: String {
        switch member.syncStatus {
        case .synced: return loc.t("profile.sync.synced")
        case .pendingUpload: return loc.t("profile.sync.pendingUpload")
        case .pendingDownload: return loc.t("profile.sync.pendingDownload")
        case .conflict: return loc.t("profile.sync.conflict")
        case .syncFailed: return loc.t("profile.sync.failed")
        }
    }

    private func saveChanges() {
        member.markDirty()
        try? modelContext.save()
        Task { await syncEngine?.syncNow() }
    }
}

/// Estado de los campos editables de `Member` en el momento de entrar en
/// modo edición. `apply(to:)` los restaura si el usuario cancela.
private struct MemberEditSnapshot {
    let firstName: String
    let firstSurname: String
    let secondSurname: String
    let email: String
    let secondaryEmail: String
    let mobilePhone: String
    let landlinePhone: String
    let address: String
    let postalCode: String
    let city: String
    let province: String
    let entryYear: String
    let exitYear: String
    let promotion: String
    let profession: String
    let workplace: String
    let iban: String
    let facebookUsername: String
    let instagramUsername: String
    let xUsername: String
    let tiktokUsername: String
    let isSearchable: Bool
    let photoData: Data?

    init(member: Member) {
        firstName = member.firstName
        firstSurname = member.firstSurname
        secondSurname = member.secondSurname
        email = member.email
        secondaryEmail = member.secondaryEmail
        mobilePhone = member.mobilePhone
        landlinePhone = member.landlinePhone
        address = member.address
        postalCode = member.postalCode
        city = member.city
        province = member.province
        entryYear = member.entryYear
        exitYear = member.exitYear
        promotion = member.promotion
        profession = member.profession
        workplace = member.workplace
        iban = member.iban
        facebookUsername = member.facebookUsername
        instagramUsername = member.instagramUsername
        xUsername = member.xUsername
        tiktokUsername = member.tiktokUsername
        isSearchable = member.isSearchable
        photoData = member.photoData
    }

    func apply(to member: Member) {
        member.firstName = firstName
        member.firstSurname = firstSurname
        member.secondSurname = secondSurname
        member.email = email
        member.secondaryEmail = secondaryEmail
        member.mobilePhone = mobilePhone
        member.landlinePhone = landlinePhone
        member.address = address
        member.postalCode = postalCode
        member.city = city
        member.province = province
        member.entryYear = entryYear
        member.exitYear = exitYear
        member.promotion = promotion
        member.profession = profession
        member.workplace = workplace
        member.iban = iban
        member.facebookUsername = facebookUsername
        member.instagramUsername = instagramUsername
        member.xUsername = xUsername
        member.tiktokUsername = tiktokUsername
        member.isSearchable = isSearchable
        member.photoData = photoData
    }
}

/// Campo de formulario que alterna entre texto de solo lectura y `TextField`
/// editable, según `isEditing`.
private struct LabeledField: View {
    let label: String
    @Binding var text: String
    let isEditing: Bool

    var body: some View {
        if isEditing {
            TextField(label, text: $text)
        } else if !text.isEmpty {
            LabeledContent(label, value: text)
        }
    }
}

#Preview {
    let container = PersistenceController.inMemoryContainer()
    let member = Member(
        firstName: "Ana", firstSurname: "García", secondSurname: "López",
        email: "ana@example.com", mobilePhone: "600123456",
        address: "Calle Mayor 1", postalCode: "08001", city: "Barcelona", province: "Barcelona",
        membershipStatus: .pendingApproval
    )
    container.mainContext.insert(member)
    return MemberProfileView(member: member)
        .environment(LocalizationManager())
        .modelContainer(container)
}

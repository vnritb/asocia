import SwiftUI

/// Creación de una nueva sala de tipo "actividad": como un grupo, pero con
/// un calendario de eventos asociado (ver `EventsListView`). La gestión de
/// los eventos (crear, editar, invitar) la hace el equipo administrador
/// desde el backoffice; desde la app, cualquier socio de la sala puede
/// consultar los eventos y confirmar su asistencia.
struct NewActivityView: View {
    var onCreated: (Conversation) -> Void

    @Environment(\.chatService) private var chatService
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    @State private var activityName = ""
    @State private var photoData: Data?
    @State private var directory: [ChatUser] = []
    @State private var selectedUserIDs: Set<UUID> = []
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        MemberPhotoPicker(photoData: $photoData)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } footer: {
                    Text(loc.t("newActivity.photoFooter"))
                }

                Section(loc.t("newActivity.nameSection")) {
                    TextField(loc.t("newActivity.namePlaceholder"), text: $activityName)
                }

                Section(loc.t("newActivity.participantsSection", count: selectedUserIDs.count)) {
                    ForEach(directory) { user in
                        Button {
                            toggle(user)
                        } label: {
                            HStack {
                                Text(user.fullName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedUserIDs.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(loc.t("newActivity.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc.t("common.create")) {
                        Task { await create() }
                    }
                    .disabled(activityName.trimmingCharacters(in: .whitespaces).isEmpty || selectedUserIDs.isEmpty || isCreating)
                }
            }
            .task {
                directory = await chatService.searchDirectory(query: "")
            }
        }
    }

    private func toggle(_ user: ChatUser) {
        if selectedUserIDs.contains(user.id) {
            selectedUserIDs.remove(user.id)
        } else {
            selectedUserIDs.insert(user.id)
        }
    }

    private func create() async {
        isCreating = true
        defer { isCreating = false }
        do {
            let conversation = try await chatService.createActivityConversation(
                name: activityName, participantIDs: Array(selectedUserIDs), photoData: photoData
            )
            onCreated(conversation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NewActivityView { _ in }
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}

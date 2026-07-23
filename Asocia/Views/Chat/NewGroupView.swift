import SwiftUI

/// Creación de una nueva sala de grupo. A diferencia de las conversaciones
/// individuales (limitadas a una por pareja), de grupos se pueden crear
/// tantos como se quiera.
struct NewGroupView: View {
    var onCreated: (Conversation) -> Void

    @Environment(\.chatService) private var chatService
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    @State private var groupName = ""
    @State private var directory: [ChatUser] = []
    @State private var selectedUserIDs: Set<UUID> = []
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(loc.t("newGroup.nameSection")) {
                    TextField(loc.t("newGroup.namePlaceholder"), text: $groupName)
                }

                Section(loc.t("newGroup.participantsSection", count: selectedUserIDs.count)) {
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
            .navigationTitle(loc.t("newGroup.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc.t("common.create")) {
                        Task { await create() }
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || selectedUserIDs.isEmpty || isCreating)
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
            let conversation = try await chatService.createGroupConversation(
                name: groupName, participantIDs: Array(selectedUserIDs)
            )
            onCreated(conversation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NewGroupView { _ in }
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}

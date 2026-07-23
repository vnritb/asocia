import SwiftUI

/// Buscador de socios para abrir (o crear) una conversación individual.
///
/// Regla de negocio: solo puede existir una conversación individual por
/// pareja de usuarios. `chatService.openOrCreateIndividualConversation` se
/// encarga de devolver la ya existente si ya la había, en vez de duplicarla.
struct UserSearchView: View {
    var onOpenConversation: (Conversation) -> Void

    @Environment(\.chatService) private var chatService
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    @State private var query = ""
    @State private var results: [ChatUser] = []
    @State private var isOpening = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List(results) { user in
                Button {
                    Task { await open(user) }
                } label: {
                    HStack(spacing: 12) {
                        avatar(for: user)
                        Text(user.fullName)
                        Spacer()
                        if isOpening {
                            ProgressView()
                        }
                    }
                }
                .disabled(isOpening)
            }
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, prompt: loc.t("userSearch.prompt"))
            .navigationTitle(loc.t("userSearch.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.close")) { dismiss() }
                }
            }
            .task(id: query) { await search() }
            .alert(loc.t("userSearch.errorTitle"), isPresented: .constant(errorMessage != nil), actions: {
                Button(loc.t("common.ok")) { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    private func search() async {
        results = await chatService.searchDirectory(query: query)
    }

    private func open(_ user: ChatUser) async {
        isOpening = true
        defer { isOpening = false }
        do {
            let conversation = try await chatService.openOrCreateIndividualConversation(with: user.id)
            onOpenConversation(conversation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func avatar(for user: ChatUser) -> some View {
        ZStack {
            Circle().fill(Color.accentColor.opacity(0.2))
            if let data = user.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Text(String(user.fullName.prefix(1)))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}

#Preview {
    UserSearchView { _ in }
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}

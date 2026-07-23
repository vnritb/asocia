import SwiftUI

/// Pantalla de una sala de chat (individual, de grupo o de actividad).
///
/// En las salas de tipo `activity` se muestra además un botón para ver los
/// eventos del calendario asociado (ver `EventsListView`).
///
/// Como `MockChatService` no tiene push real, esta vista hace "polling"
/// ligero (cada 2s mientras está abierta) para detectar la respuesta
/// simulada de la otra parte. Cuando haya un backend real con WebSockets,
/// este bucle se sustituye por un stream de mensajes entrantes.
struct ConversationView: View {
    let conversation: Conversation
    let title: String
    let currentUserID: UUID

    @Environment(\.chatService) private var chatService
    @Environment(LocalizationManager.self) private var loc

    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            if conversation.kind == .activity {
                NavigationLink {
                    EventsListView(conversation: conversation, currentUserID: currentUserID)
                } label: {
                    Label(loc.t("conversation.eventsButton"), systemImage: "calendar")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, isMine: message.senderID == currentUserID, showsSender: conversation.kind != .individual)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages) { _, _ in
                    if let lastID = messages.last?.id {
                        withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField(loc.t("conversation.messagePlaceholder"), text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refresh()
            // Sondeo ligero mientras la sala está abierta, para ver la
            // respuesta simulada de la otra persona sin salir y volver a entrar.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                await refresh()
            }
        }
    }

    private func refresh() async {
        messages = await chatService.fetchMessages(conversationID: conversation.id)
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        isSending = true
        defer { isSending = false }
        _ = try? await chatService.sendMessage(conversationID: conversation.id, text: text)
        await refresh()
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool
    let showsSender: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }

            VStack(alignment: .leading, spacing: 2) {
                if showsSender, !isMine {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMine ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(isMine ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if !isMine { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    NavigationStack {
        ConversationView(
            conversation: Conversation(id: UUID(), kind: .individual, title: "", participantIDs: [], lastMessagePreview: "", lastMessageAt: nil),
            title: "Marta Puig",
            currentUserID: UUID()
        )
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
    }
}

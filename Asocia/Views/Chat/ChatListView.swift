import SwiftUI

/// Lista de conversaciones del socio (individuales, de grupo y de
/// actividad). Solo se muestra cuando `member.membershipStatus.hasChatAccess`
/// es cierto — lo garantiza `RootView`/`MainTabView`, que ni siquiera crea
/// esta pestaña si el alta todavía no está confirmada.
struct ChatListView: View {
    let member: Member

    @Environment(\.chatService) private var chatService
    @Environment(LocalizationManager.self) private var loc

    @State private var conversations: [Conversation] = []
    @State private var directoryByID: [UUID: ChatUser] = [:]
    @State private var showSearch = false
    @State private var showNewGroup = false
    @State private var showNewActivity = false
    @State private var showActivitiesDirectory = false
    @State private var navigationConversation: Conversation?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if conversations.isEmpty {
                    ContentUnavailableView(
                        loc.t("chatList.empty.title"),
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text(loc.t("chatList.empty.description"))
                    )
                } else {
                    List(conversations) { conversation in
                        Button {
                            navigationConversation = conversation
                        } label: {
                            ConversationRow(conversation: conversation, otherUser: otherUser(for: conversation), loc: loc)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(loc.t("chatList.navTitle"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showNewGroup = true
                        } label: {
                            Label(loc.t("chatList.newGroup"), systemImage: "person.3")
                        }
                        Button {
                            showNewActivity = true
                        } label: {
                            Label(loc.t("chatList.newActivity"), systemImage: "calendar.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showActivitiesDirectory = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                    .accessibilityLabel(loc.t("chatList.exploreActivities"))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showActivitiesDirectory, onDismiss: { Task { await reload() } }) {
                ActivitiesDirectoryView(currentUserID: member.id)
            }
            .sheet(isPresented: $showSearch) {
                UserSearchView { conversation in
                    navigationConversation = conversation
                    Task { await reload() }
                }
            }
            .sheet(isPresented: $showNewGroup) {
                NewGroupView { conversation in
                    navigationConversation = conversation
                    Task { await reload() }
                }
            }
            .sheet(isPresented: $showNewActivity) {
                NewActivityView { conversation in
                    navigationConversation = conversation
                    Task { await reload() }
                }
            }
            .navigationDestination(item: $navigationConversation) { conversation in
                ConversationView(
                    conversation: conversation,
                    title: title(for: conversation),
                    currentUserID: member.id
                )
            }
            .task {
                await chatService.configureCurrentUser(id: member.id, name: member.fullName, photoData: member.photoData)
                await reload()
            }
            .refreshable { await reload() }
        }
    }

    private func reload() async {
        async let fetchedConversations = chatService.fetchConversations()
        async let fetchedDirectory = chatService.searchDirectory(query: "")
        let (convs, directory) = await (fetchedConversations, fetchedDirectory)
        conversations = convs
        directoryByID = Dictionary(uniqueKeysWithValues: directory.map { ($0.id, $0) })
        isLoading = false
    }

    private func otherUser(for conversation: Conversation) -> ChatUser? {
        guard let otherID = conversation.otherParticipantID(currentUserID: member.id) else { return nil }
        return directoryByID[otherID]
    }

    private func title(for conversation: Conversation) -> String {
        if conversation.kind != .individual {
            return conversation.title
        }
        return otherUser(for: conversation)?.fullName ?? loc.t("chatList.defaultMemberName")
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    let otherUser: ChatUser?
    let loc: LocalizationManager

    private var title: String {
        conversation.kind == .individual ? (otherUser?.fullName ?? loc.t("chatList.defaultMemberName")) : conversation.title
    }

    private var kindIcon: String? {
        switch conversation.kind {
        case .group: return "person.3.fill"
        case .activity: return "calendar"
        case .individual: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).font(.headline)
                    if let kindIcon {
                        Image(systemName: kindIcon)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(conversation.lastMessagePreview.isEmpty ? loc.t("chatList.noMessages") : conversation.lastMessagePreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let date = conversation.lastMessageAt {
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var avatar: some View {
        ZStack {
            Circle().fill(Color.accentColor.opacity(0.2))
            if let data = conversation.photoData ?? otherUser?.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else if let kindIcon {
                Image(systemName: kindIcon).foregroundStyle(Color.accentColor)
            } else {
                Text(String(title.prefix(1)))
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}

#Preview {
    ChatListView(member: Member(firstName: "Ana", firstSurname: "García", membershipStatus: .active))
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}

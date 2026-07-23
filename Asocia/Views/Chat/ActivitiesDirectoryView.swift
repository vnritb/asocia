import SwiftUI

/// Listado de TODAS las actividades que existen (no solo las tuyas), con
/// iconos grandes: foto, título y fecha del próximo evento. Cualquier socio
/// puede solicitar acceso a una actividad de la que todavía no forma parte.
struct ActivitiesDirectoryView: View {
    let currentUserID: UUID

    @Environment(\.chatService) private var chatService
    @Environment(LocalizationManager.self) private var loc

    @State private var activities: [ActivitySummary] = []
    @State private var isLoading = true
    @State private var requestingIDs: Set<UUID> = []
    @State private var sentRequestIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var navigationConversation: Conversation?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if activities.isEmpty {
                    ContentUnavailableView(loc.t("activities.empty"), systemImage: "calendar.badge.plus")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(activities) { activity in
                                ActivityCard(
                                    activity: activity,
                                    loc: loc,
                                    isRequesting: requestingIDs.contains(activity.id),
                                    requestSent: sentRequestIDs.contains(activity.id),
                                    onOpen: { navigationConversation = activity.conversation },
                                    onRequestAccess: { Task { await requestAccess(activity) } }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(loc.t("activities.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $navigationConversation) { conversation in
                ConversationView(conversation: conversation, title: conversation.title, currentUserID: currentUserID)
            }
            .task { await reload() }
            .refreshable { await reload() }
            .alert(loc.t("activities.requestErrorTitle"), isPresented: Binding(
                get: { errorMessage != nil }, set: { _ in }
            )) {
                Button(loc.t("common.ok")) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func reload() async {
        activities = await chatService.fetchAllActivities()
        isLoading = false
    }

    private func requestAccess(_ activity: ActivitySummary) async {
        requestingIDs.insert(activity.id)
        defer { requestingIDs.remove(activity.id) }
        do {
            try await chatService.requestAccessToActivity(conversationID: activity.id)
            sentRequestIDs.insert(activity.id)
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ActivityCard: View {
    let activity: ActivitySummary
    let loc: LocalizationManager
    let isRequesting: Bool
    let requestSent: Bool
    let onOpen: () -> Void
    let onRequestAccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            photo
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(activity.conversation.title)
                .font(.headline)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 2) {
                Text(loc.t("activities.nextEventLabel"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let date = activity.nextEventDate {
                    Text(date, format: .dateTime.day().month(.wide).year())
                        .font(.caption)
                } else {
                    Text(loc.t("activities.noUpcomingEvent"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            actionButton
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var photo: some View {
        if let data = activity.conversation.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage).resizable().scaledToFill()
        } else {
            ZStack {
                Color.accentColor.opacity(0.2)
                Image(systemName: "calendar")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if activity.isParticipant {
            Button(loc.t("activities.open"), action: onOpen)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        } else if requestSent {
            Label(loc.t("activities.requestSent"), systemImage: "checkmark")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Button {
                onRequestAccess()
            } label: {
                if isRequesting {
                    ProgressView()
                } else {
                    Text(loc.t("activities.requestAccess"))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isRequesting)
        }
    }
}

#Preview {
    ActivitiesDirectoryView(currentUserID: UUID())
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}

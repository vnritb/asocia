import SwiftUI

/// Punto de entrada a los eventos de una sala de tipo `activity`.
///
/// Regla pedida: si solo hay un evento, se muestra directamente su ficha;
/// si hay más de uno, se ofrece elegir entre verlos en lista o en un
/// calendario con los días marcados.
struct EventsListView: View {
    let conversation: Conversation
    let currentUserID: UUID

    @Environment(\.chatService) private var chatService
    @Environment(LocalizationManager.self) private var loc

    @State private var events: [ActivityEvent] = []
    @State private var isLoading = true
    @State private var viewMode: ViewMode = .list
    @State private var selectedDateComponents: DateComponents?

    private enum ViewMode { case list, calendar }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if events.isEmpty {
                ContentUnavailableView(loc.t("events.empty"), systemImage: "calendar")
            } else if events.count == 1, let onlyEvent = events.first {
                EventDetailView(event: onlyEvent, currentUserID: currentUserID, onAttendanceConfirmed: replace)
            } else {
                VStack(spacing: 0) {
                    Picker(loc.t("events.viewMode"), selection: $viewMode) {
                        Text(loc.t("events.viewList")).tag(ViewMode.list)
                        Text(loc.t("events.viewCalendar")).tag(ViewMode.calendar)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if viewMode == .list {
                        listContent
                    } else {
                        calendarContent
                    }
                }
            }
        }
        .navigationTitle(loc.t("events.navTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
    }

    private var listContent: some View {
        List(events) { event in
            NavigationLink {
                EventDetailView(event: event, currentUserID: currentUserID, onAttendanceConfirmed: replace)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title).font(.headline)
                    Text(event.startDate, format: .dateTime.day().month(.wide).year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }

    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            EventCalendarView(events: events, selectedDate: $selectedDateComponents)
                .frame(height: 380)
                .padding(.horizontal)

            Text(loc.t("events.selectedDay"))
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal)

            if let selectedDateComponents, let date = Calendar.current.date(from: selectedDateComponents) {
                let dayEvents = events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
                if dayEvents.isEmpty {
                    Text(loc.t("events.noEventsThisDay"))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Spacer()
                } else {
                    List(dayEvents) { event in
                        NavigationLink {
                            EventDetailView(event: event, currentUserID: currentUserID, onAttendanceConfirmed: replace)
                        } label: {
                            Text(event.title)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                Spacer()
            }
        }
    }

    private func reload() async {
        events = await chatService.fetchEvents(conversationID: conversation.id)
        isLoading = false
    }

    private func replace(_ updated: ActivityEvent) {
        if let index = events.firstIndex(where: { $0.id == updated.id }) {
            events[index] = updated
        }
    }
}

#Preview {
    NavigationStack {
        EventsListView(
            conversation: Conversation(id: UUID(), kind: .activity, title: "Excursiones", participantIDs: [], lastMessagePreview: "", lastMessageAt: nil),
            currentUserID: UUID()
        )
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
    }
}

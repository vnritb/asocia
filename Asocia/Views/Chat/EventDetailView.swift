import SwiftUI

/// Ficha de un evento (esdeveniment): descripción, fecha, lugar, asistentes
/// y dos acciones para el socio: confirmar su asistencia y exportarlo al
/// calendario nativo del iPhone (EventKit).
struct EventDetailView: View {
    let event: ActivityEvent
    let currentUserID: UUID
    /// Se llama cuando el socio confirma asistencia, para que la vista que
    /// contiene esta (lista o calendario) pueda refrescar su copia del evento.
    var onAttendanceConfirmed: ((ActivityEvent) -> Void)?

    @Environment(\.chatService) private var chatService
    @Environment(LocalizationManager.self) private var loc

    @State private var isConfirming = false
    @State private var isExporting = false
    @State private var didExport = false
    @State private var errorMessage: String?

    private var myStatus: EventAttendeeStatus? {
        event.attendee(id: currentUserID)?.status
    }

    private var invited: [EventAttendee] {
        event.attendees.filter { $0.status == .invited }
    }
    private var confirmed: [EventAttendee] {
        event.attendees.filter { $0.status == .confirmed }
    }

    var body: some View {
        Form {
            Section {
                Text(event.title)
                    .font(.title3.weight(.semibold))
                if !event.eventDescription.isEmpty {
                    Text(event.eventDescription)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent(loc.t("event.field.date")) {
                    Text(event.startDate, format: .dateTime.day().month(.wide).year().hour().minute())
                }
                if !event.location.isEmpty {
                    LabeledContent(loc.t("event.field.location"), value: event.location)
                }
            }

            Section(loc.t("event.section.attendees", count: event.attendees.count)) {
                ForEach(confirmed) { attendee in
                    HStack {
                        Text(attendee.name)
                        Spacer()
                        Text(loc.t("event.attendee.confirmed"))
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                ForEach(invited) { attendee in
                    HStack {
                        Text(attendee.name)
                        Spacer()
                        Text(loc.t("event.attendee.invited"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                if myStatus == .confirmed {
                    Label(loc.t("event.rsvp.confirmed"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if myStatus == .invited {
                    Button {
                        Task { await confirmAttendance() }
                    } label: {
                        if isConfirming {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(loc.t("event.rsvp.confirm")).frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isConfirming)
                }

                Button {
                    Task { await exportToCalendar() }
                } label: {
                    if isExporting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label(
                            didExport ? loc.t("event.addedToCalendar") : loc.t("event.addToCalendar"),
                            systemImage: didExport ? "checkmark" : "calendar.badge.plus"
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isExporting || didExport)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(loc.t("event.detail.navTitle"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func confirmAttendance() async {
        isConfirming = true
        defer { isConfirming = false }
        do {
            let updated = try await chatService.confirmAttendance(eventID: event.id)
            onAttendanceConfirmed?(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportToCalendar() async {
        isExporting = true
        defer { isExporting = false }
        do {
            try await CalendarExporter.addToCalendar(event)
            didExport = true
        } catch CalendarExporterError.accessDenied {
            errorMessage = loc.t("event.calendarPermissionDenied")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(
            event: ActivityEvent(
                id: UUID(), conversationID: UUID(), title: "Excursión anual",
                eventDescription: "Salida de senderismo por Collserola.",
                startDate: .now.addingTimeInterval(86400 * 5), endDate: nil,
                location: "Parc de Collserola",
                attendees: [EventAttendee(id: UUID(), name: "Marta Puig", status: .confirmed)]
            ),
            currentUserID: UUID()
        )
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
    }
}

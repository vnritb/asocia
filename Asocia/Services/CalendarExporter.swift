import Foundation
import EventKit

/// Sin conformar `LocalizedError` a propósito: el texto que ve el usuario
/// sale del diccionario de `LocalizationManager` (clave
/// `event.calendarPermissionDenied` para `.accessDenied`), no de aquí, para
/// que también se traduzca al cambiar de idioma.
enum CalendarExporterError: Error {
    case accessDenied
    case saveFailed(Error)
}

/// Exporta un `ActivityEvent` al calendario nativo del iPhone usando
/// EventKit. Requiere el permiso `NSCalendarsFullAccessUsageDescription`
/// (ya incluido en `project.yml`).
enum CalendarExporter {
    @MainActor
    static func addToCalendar(_ event: ActivityEvent) async throws {
        let store = EKEventStore()

        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = try await store.requestFullAccessToEvents()
        } else {
            granted = try await store.requestAccess(to: .event)
        }
        guard granted else { throw CalendarExporterError.accessDenied }

        let ekEvent = EKEvent(eventStore: store)
        ekEvent.title = event.title
        ekEvent.notes = event.eventDescription
        ekEvent.location = event.location.isEmpty ? nil : event.location
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate ?? event.startDate.addingTimeInterval(2 * 60 * 60)
        ekEvent.calendar = store.defaultCalendarForNewEvents

        do {
            try store.save(ekEvent, span: .thisEvent)
        } catch {
            throw CalendarExporterError.saveFailed(error)
        }
    }
}

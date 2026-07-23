import SwiftUI

/// Envoltorio de `UICalendarView` (UIKit) que marca con un punto los días
/// que tienen algún evento. SwiftUI todavía no tiene un componente de
/// calendario "con eventos marcados" propio, así que se usa el nativo de
/// UIKit — es el mismo componente que usa la app Calendario de Apple.
struct EventCalendarView: UIViewRepresentable {
    let events: [ActivityEvent]
    @Binding var selectedDate: DateComponents?

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = .current
        view.delegate = context.coordinator
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = selection
        return view
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.events = events
        uiView.reloadDecorations(forDateComponents: eventDateComponents, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(events: events, selectedDate: $selectedDate)
    }

    private var eventDateComponents: [DateComponents] {
        events.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.startDate) }
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var events: [ActivityEvent]
        var selectedDate: Binding<DateComponents?>

        init(events: [ActivityEvent], selectedDate: Binding<DateComponents?>) {
            self.events = events
            self.selectedDate = selectedDate
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let hasEvent = events.contains { event in
                let comps = Calendar.current.dateComponents([.year, .month, .day], from: event.startDate)
                return comps.year == dateComponents.year && comps.month == dateComponents.month && comps.day == dateComponents.day
            }
            return hasEvent ? .default(color: .systemOrange, size: .medium) : nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            selectedDate.wrappedValue = dateComponents
        }
    }
}

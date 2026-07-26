import Foundation
import Observation

/// Gestor de localización que proporciona traducciones estáticas para la app.
/// Soporta múltiples idiomas y permite cambiar el idioma en tiempo de ejecución.
@Observable
class LocalizationManager {
    
    // MARK: - Properties
    
    /// Código del idioma actual (ISO 639-1: "es", "ca", "en", etc.)
    private(set) var currentLanguageCode: String {
        didSet {
            UserDefaults.standard.set(currentLanguageCode, forKey: "AppLanguage")
        }
    }
    
    /// Indica si hay una traducción en progreso
    private(set) var isTranslating: Bool = false
    
    /// Error de traducción (si ocurre)
    private(set) var translationError: String? = nil
    
    // MARK: - Initialization
    
    init() {
        // Cargar el idioma guardado o usar el del sistema
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            self.currentLanguageCode = savedLanguage
        } else {
            // Detectar idioma del sistema
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "es"
            self.currentLanguageCode = systemLanguage
        }
    }
    
    // MARK: - Public Methods
    
    /// Cambia el idioma actual
    /// - Parameter code: Código ISO 639-1 del idioma (ej: "es", "ca", "en")
    @MainActor
    func setLanguage(_ code: String) async {
        isTranslating = true
        translationError = nil
        
        // Simular un pequeño delay para dar feedback visual
        try? await Task.sleep(for: .milliseconds(300))
        
        currentLanguageCode = code
        isTranslating = false
    }
    
    /// Traduce una clave al idioma actual
    /// - Parameter key: Clave de traducción en formato punto (ej: "chatList.navTitle")
    /// - Parameter count: Parámetro opcional para pluralización
    /// - Returns: Texto traducido o la clave si no existe traducción
    func t(_ key: String, count: Int? = nil) -> String {
        let baseTranslation = translations[currentLanguageCode]?[key] ?? translations["es"]?[key] ?? key
        
        // Si se proporciona un count, intentar reemplazar placeholders
        if let count = count {
            return baseTranslation.replacingOccurrences(of: "{count}", with: "\(count)")
        }
        
        return baseTranslation
    }
    
    // MARK: - Translations
    
    /// Diccionario de traducciones: [idioma: [clave: valor]]
    private let translations: [String: [String: String]] = [
        "es": [
            // Tabs
            "tab.profile": "Ficha",
            "tab.chat": "Chat",
            "tab.settings": "Ajustes",
            
            // Chat List
            "chatList.navTitle": "Conversaciones",
            "chatList.empty.title": "Sin conversaciones",
            "chatList.empty.description": "Inicia una conversación con otros socios",
            "chatList.newGroup": "Nuevo Grupo",
            "chatList.newActivity": "Nueva Actividad",
            "chatList.exploreActivities": "Explorar Actividades",
            "chatList.defaultMemberName": "Socio",
            "chatList.noMessages": "Sin mensajes",
            
            // Settings
            "settings.navTitle": "Ajustes",
            "settings.language.current": "Idioma",
            "settings.language.footer": "Cambia el idioma de la aplicación",
            "settings.language.translating": "Cambiando idioma...",
            "settings.language.errorTitle": "Error",
            
            // Common
            "common.ok": "Aceptar",
            "common.cancel": "Cancelar",
            "common.create": "Crear",
            
            // Membership Button
            "membershipButton.accessibilityHint": "Pulsa para asociarte",
            
            // New Group
            "newGroup.navTitle": "Nuevo Grupo",
            "newGroup.nameSection": "Nombre del grupo",
            "newGroup.namePlaceholder": "Introduce el nombre",
            "newGroup.participantsSection": "Participantes ({count})",
            
            // New Activity
            "newActivity.navTitle": "Nueva Actividad",
            "newActivity.nameSection": "Nombre de la actividad",
            "newActivity.namePlaceholder": "Introduce el nombre",
            "newActivity.participantsSection": "Participantes ({count})",
            "newActivity.photoFooter": "Añade una foto para la actividad",
            
            // Events
            "events.navTitle": "Eventos",
            "events.empty": "No hay eventos",
            "events.viewMode": "Modo de vista",
            "events.viewList": "Lista",
            "events.viewCalendar": "Calendario",
            "events.selectedDay": "Eventos del día seleccionado",
            "events.noEventsThisDay": "No hay eventos este día",
            
            // Event Detail
            "event.detail.navTitle": "Evento",
            "event.field.date": "Fecha",
            "event.field.location": "Lugar",
            "event.section.attendees": "Asistentes ({count})",
            "event.attendee.confirmed": "Confirmado",
            "event.attendee.invited": "Invitado",
            "event.rsvp.confirmed": "Asistencia confirmada",
            "event.rsvp.confirm": "Confirmar asistencia",
            "event.addToCalendar": "Añadir al calendario",
            "event.addedToCalendar": "Añadido al calendario",
            "event.calendarPermissionDenied": "No tienes permisos para acceder al calendario",
            
            // Activities Directory
            "activities.navTitle": "Todas las Actividades",
            "activities.empty": "No hay actividades disponibles",
            "activities.nextEventLabel": "Próximo evento:",
            "activities.noUpcomingEvent": "Sin eventos próximos",
            "activities.open": "Abrir",
            "activities.requestAccess": "Solicitar acceso",
            "activities.requestSent": "Solicitud enviada",
            "activities.requestErrorTitle": "Error al solicitar acceso",
        ],
        
        "ca": [
            // Tabs
            "tab.profile": "Fitxa",
            "tab.chat": "Xat",
            "tab.settings": "Configuració",
            
            // Chat List
            "chatList.navTitle": "Converses",
            "chatList.empty.title": "Sense converses",
            "chatList.empty.description": "Inicia una conversa amb altres socis",
            "chatList.newGroup": "Nou Grup",
            "chatList.newActivity": "Nova Activitat",
            "chatList.exploreActivities": "Explorar Activitats",
            "chatList.defaultMemberName": "Soci",
            "chatList.noMessages": "Sense missatges",
            
            // Settings
            "settings.navTitle": "Configuració",
            "settings.language.current": "Idioma",
            "settings.language.footer": "Canvia l'idioma de l'aplicació",
            "settings.language.translating": "Canviant idioma...",
            "settings.language.errorTitle": "Error",
            
            // Common
            "common.ok": "Acceptar",
            "common.cancel": "Cancel·lar",
            "common.create": "Crear",
            
            // Membership Button
            "membershipButton.accessibilityHint": "Prem per associar-te",
            
            // New Group
            "newGroup.navTitle": "Nou Grup",
            "newGroup.nameSection": "Nom del grup",
            "newGroup.namePlaceholder": "Introdueix el nom",
            "newGroup.participantsSection": "Participants ({count})",
            
            // New Activity
            "newActivity.navTitle": "Nova Activitat",
            "newActivity.nameSection": "Nom de l'activitat",
            "newActivity.namePlaceholder": "Introdueix el nom",
            "newActivity.participantsSection": "Participants ({count})",
            "newActivity.photoFooter": "Afegeix una foto per a l'activitat",
            
            // Events
            "events.navTitle": "Esdeveniments",
            "events.empty": "No hi ha esdeveniments",
            "events.viewMode": "Mode de vista",
            "events.viewList": "Llista",
            "events.viewCalendar": "Calendari",
            "events.selectedDay": "Esdeveniments del dia seleccionat",
            "events.noEventsThisDay": "No hi ha esdeveniments aquest dia",
            
            // Event Detail
            "event.detail.navTitle": "Esdeveniment",
            "event.field.date": "Data",
            "event.field.location": "Lloc",
            "event.section.attendees": "Assistents ({count})",
            "event.attendee.confirmed": "Confirmat",
            "event.attendee.invited": "Convidat",
            "event.rsvp.confirmed": "Assistència confirmada",
            "event.rsvp.confirm": "Confirmar assistència",
            "event.addToCalendar": "Afegir al calendari",
            "event.addedToCalendar": "Afegit al calendari",
            "event.calendarPermissionDenied": "No tens permisos per accedir al calendari",
            
            // Activities Directory
            "activities.navTitle": "Totes les Activitats",
            "activities.empty": "No hi ha activitats disponibles",
            "activities.nextEventLabel": "Proper esdeveniment:",
            "activities.noUpcomingEvent": "Sense esdeveniments propers",
            "activities.open": "Obrir",
            "activities.requestAccess": "Sol·licitar accés",
            "activities.requestSent": "Sol·licitud enviada",
            "activities.requestErrorTitle": "Error en sol·licitar accés",
        ],
        
        "en": [
            // Tabs
            "tab.profile": "Profile",
            "tab.chat": "Chat",
            "tab.settings": "Settings",
            
            // Chat List
            "chatList.navTitle": "Conversations",
            "chatList.empty.title": "No conversations",
            "chatList.empty.description": "Start a conversation with other members",
            "chatList.newGroup": "New Group",
            "chatList.newActivity": "New Activity",
            "chatList.exploreActivities": "Explore Activities",
            "chatList.defaultMemberName": "Member",
            "chatList.noMessages": "No messages",
            
            // Settings
            "settings.navTitle": "Settings",
            "settings.language.current": "Language",
            "settings.language.footer": "Change the app language",
            "settings.language.translating": "Changing language...",
            "settings.language.errorTitle": "Error",
            
            // Common
            "common.ok": "OK",
            "common.cancel": "Cancel",
            "common.create": "Create",
            
            // Membership Button
            "membershipButton.accessibilityHint": "Tap to become a member",
            
            // New Group
            "newGroup.navTitle": "New Group",
            "newGroup.nameSection": "Group name",
            "newGroup.namePlaceholder": "Enter name",
            "newGroup.participantsSection": "Participants ({count})",
            
            // New Activity
            "newActivity.navTitle": "New Activity",
            "newActivity.nameSection": "Activity name",
            "newActivity.namePlaceholder": "Enter name",
            "newActivity.participantsSection": "Participants ({count})",
            "newActivity.photoFooter": "Add a photo for the activity",
            
            // Events
            "events.navTitle": "Events",
            "events.empty": "No events",
            "events.viewMode": "View mode",
            "events.viewList": "List",
            "events.viewCalendar": "Calendar",
            "events.selectedDay": "Events for selected day",
            "events.noEventsThisDay": "No events this day",
            
            // Event Detail
            "event.detail.navTitle": "Event",
            "event.field.date": "Date",
            "event.field.location": "Location",
            "event.section.attendees": "Attendees ({count})",
            "event.attendee.confirmed": "Confirmed",
            "event.attendee.invited": "Invited",
            "event.rsvp.confirmed": "Attendance confirmed",
            "event.rsvp.confirm": "Confirm attendance",
            "event.addToCalendar": "Add to calendar",
            "event.addedToCalendar": "Added to calendar",
            "event.calendarPermissionDenied": "You don't have permission to access the calendar",
            
            // Activities Directory
            "activities.navTitle": "All Activities",
            "activities.empty": "No activities available",
            "activities.nextEventLabel": "Next event:",
            "activities.noUpcomingEvent": "No upcoming events",
            "activities.open": "Open",
            "activities.requestAccess": "Request access",
            "activities.requestSent": "Request sent",
            "activities.requestErrorTitle": "Error requesting access",
        ],
        
        "gl": [
            // Tabs
            "tab.profile": "Ficha",
            "tab.chat": "Chat",
            "tab.settings": "Axustes",
            
            // Chat List
            "chatList.navTitle": "Conversas",
            "chatList.empty.title": "Sen conversas",
            "chatList.empty.description": "Inicia unha conversa con outros socios",
            "chatList.newGroup": "Novo Grupo",
            "chatList.newActivity": "Nova Actividade",
            "chatList.exploreActivities": "Explorar Actividades",
            "chatList.defaultMemberName": "Socio",
            "chatList.noMessages": "Sen mensaxes",
            
            // Settings
            "settings.navTitle": "Axustes",
            "settings.language.current": "Idioma",
            "settings.language.footer": "Cambia o idioma da aplicación",
            "settings.language.translating": "Cambiando idioma...",
            "settings.language.errorTitle": "Erro",
            
            // Common
            "common.ok": "Aceptar",
            "common.cancel": "Cancelar",
            "common.create": "Crear",
            
            // Membership Button
            "membershipButton.accessibilityHint": "Preme para asociarte",
            
            // New Group
            "newGroup.navTitle": "Novo Grupo",
            "newGroup.nameSection": "Nome do grupo",
            "newGroup.namePlaceholder": "Introduce o nome",
            "newGroup.participantsSection": "Participantes ({count})",
            
            // New Activity
            "newActivity.navTitle": "Nova Actividade",
            "newActivity.nameSection": "Nome da actividade",
            "newActivity.namePlaceholder": "Introduce o nome",
            "newActivity.participantsSection": "Participantes ({count})",
            "newActivity.photoFooter": "Engade unha foto para a actividade",
            
            // Events
            "events.navTitle": "Eventos",
            "events.empty": "Non hai eventos",
            "events.viewMode": "Modo de vista",
            "events.viewList": "Lista",
            "events.viewCalendar": "Calendario",
            "events.selectedDay": "Eventos do día seleccionado",
            "events.noEventsThisDay": "Non hai eventos este día",
            
            // Event Detail
            "event.detail.navTitle": "Evento",
            "event.field.date": "Data",
            "event.field.location": "Lugar",
            "event.section.attendees": "Asistentes ({count})",
            "event.attendee.confirmed": "Confirmado",
            "event.attendee.invited": "Invitado",
            "event.rsvp.confirmed": "Asistencia confirmada",
            "event.rsvp.confirm": "Confirmar asistencia",
            "event.addToCalendar": "Engadir ao calendario",
            "event.addedToCalendar": "Engadido ao calendario",
            "event.calendarPermissionDenied": "Non tes permisos para acceder ao calendario",
            
            // Activities Directory
            "activities.navTitle": "Todas as Actividades",
            "activities.empty": "Non hai actividades dispoñibles",
            "activities.nextEventLabel": "Próximo evento:",
            "activities.noUpcomingEvent": "Sen eventos próximos",
            "activities.open": "Abrir",
            "activities.requestAccess": "Solicitar acceso",
            "activities.requestSent": "Solicitude enviada",
            "activities.requestErrorTitle": "Erro ao solicitar acceso",
        ],
        
        "eu": [
            // Tabs
            "tab.profile": "Fitxa",
            "tab.chat": "Txata",
            "tab.settings": "Ezarpenak",
            
            // Chat List
            "chatList.navTitle": "Elkarrizketak",
            "chatList.empty.title": "Ez dago elkarrizketarik",
            "chatList.empty.description": "Hasi elkarrizketa bat beste bazkideekin",
            "chatList.newGroup": "Talde Berria",
            "chatList.newActivity": "Jarduera Berria",
            "chatList.exploreActivities": "Jarduerak Arakatu",
            "chatList.defaultMemberName": "Bazkidea",
            "chatList.noMessages": "Mezurik ez",
            
            // Settings
            "settings.navTitle": "Ezarpenak",
            "settings.language.current": "Hizkuntza",
            "settings.language.footer": "Aldatu aplikazioaren hizkuntza",
            "settings.language.translating": "Hizkuntza aldatzen...",
            "settings.language.errorTitle": "Errorea",
            
            // Common
            "common.ok": "Ados",
            "common.cancel": "Utzi",
            "common.create": "Sortu",
            
            // Membership Button
            "membershipButton.accessibilityHint": "Sakatu bazkide izateko",
            
            // New Group
            "newGroup.navTitle": "Talde Berria",
            "newGroup.nameSection": "Taldearen izena",
            "newGroup.namePlaceholder": "Sartu izena",
            "newGroup.participantsSection": "Partaideak ({count})",
            
            // New Activity
            "newActivity.navTitle": "Jarduera Berria",
            "newActivity.nameSection": "Jardueraren izena",
            "newActivity.namePlaceholder": "Sartu izena",
            "newActivity.participantsSection": "Partaideak ({count})",
            "newActivity.photoFooter": "Gehitu argazki bat jarduerarako",
            
            // Events
            "events.navTitle": "Ekitaldiak",
            "events.empty": "Ez dago ekitaldirik",
            "events.viewMode": "Ikuspegi modua",
            "events.viewList": "Zerrenda",
            "events.viewCalendar": "Egutegia",
            "events.selectedDay": "Hautatutako eguneko ekitaldiak",
            "events.noEventsThisDay": "Ez dago ekitaldirik egun honetan",
            
            // Event Detail
            "event.detail.navTitle": "Ekitaldia",
            "event.field.date": "Data",
            "event.field.location": "Lekua",
            "event.section.attendees": "Bertaratzaileak ({count})",
            "event.attendee.confirmed": "Berretsia",
            "event.attendee.invited": "Gonbidatua",
            "event.rsvp.confirmed": "Bertaratzea berretsia",
            "event.rsvp.confirm": "Bertaratzea baieztatu",
            "event.addToCalendar": "Egutegira gehitu",
            "event.addedToCalendar": "Egutegira gehituta",
            "event.calendarPermissionDenied": "Ez duzu baimenik egutegira sartzeko",
            
            // Activities Directory
            "activities.navTitle": "Jarduera Guztiak",
            "activities.empty": "Ez dago jarduerarik eskuragarri",
            "activities.nextEventLabel": "Hurrengo ekitaldia:",
            "activities.noUpcomingEvent": "Hurrengo ekitaldirik ez",
            "activities.open": "Ireki",
            "activities.requestAccess": "Sarbidea eskatu",
            "activities.requestSent": "Eskaera bidalita",
            "activities.requestErrorTitle": "Errorea sarbidea eskatzerakoan",
        ]
    ]
}

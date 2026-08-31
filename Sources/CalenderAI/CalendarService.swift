import Foundation
import EventKit
import AppKit

@MainActor
class CalendarService: ObservableObject {
    static let shared = CalendarService()
    let eventStore = EKEventStore()
    
    @Published var hasAccess: Bool = false
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    private let isoFormatterWithMillis: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private let isoFormatterStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private let localDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    private let simpleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    init() {
        checkCurrentAuthorization()
    }
    
    func checkCurrentAuthorization() {
        if #available(macOS 14.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            self.authorizationStatus = status
            self.hasAccess = (status == .fullAccess)
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            self.authorizationStatus = status
            self.hasAccess = (status == .authorized)
        }
    }
    
    func parseDate(_ dateString: String) -> Date? {
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        if let date = isoFormatterWithMillis.date(from: trimmed) { return date }
        if let date = isoFormatterStandard.date(from: trimmed) { return date }
        if let date = localDateTimeFormatter.date(from: trimmed) { return date }
        if let date = simpleDateFormatter.date(from: trimmed) { return date }
        return nil
    }
    
    func requestAccess() async {
        do {
            if #available(macOS 14.0, *) {
                let granted = try await eventStore.requestFullAccessToEvents()
                self.hasAccess = granted
                self.authorizationStatus = granted ? .fullAccess : .denied
            } else {
                let granted = try await eventStore.requestAccess(to: .event)
                self.hasAccess = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
        } catch {
            print("Failed to request calendar access: \(error)")
            self.hasAccess = false
            self.authorizationStatus = .denied
        }
    }
    
    // fetchEvents
    func fetchEvents(startDate startStr: String, endDate endStr: String) -> [CalendarEventInfo] {
        guard let start = parseDate(startStr), let end = parseDate(endStr) else {
            print("Invalid date range in fetchEvents: \(startStr) - \(endStr)")
            return []
        }
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        return events.map { CalendarEventInfo(ekEvent: $0) }
    }
    
    // createEvent
    func createEvent(title: String, startDate startStr: String, endDate endStr: String, notes: String?, location: String?) throws -> CalendarEventInfo {
        guard let start = parseDate(startStr), let end = parseDate(endStr) else {
            throw NSError(domain: "CalendarError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid date format for event start/end"])
        }
        
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = title.isEmpty ? "New Event" : title
        newEvent.startDate = start
        newEvent.endDate = end > start ? end : start.addingTimeInterval(3600)
        newEvent.notes = notes
        newEvent.location = location
        
        guard let defaultCal = eventStore.defaultCalendarForNewEvents ?? eventStore.calendars(for: .event).first else {
            throw NSError(domain: "CalendarError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No default calendar found on macOS"])
        }
        newEvent.calendar = defaultCal
        
        try eventStore.save(newEvent, span: .thisEvent)
        return CalendarEventInfo(ekEvent: newEvent)
    }
    
    // updateEvent
    func updateEvent(identifier: String, newTitle: String?, newStartDate startStr: String?, newEndDate endStr: String?) throws -> CalendarEventInfo {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw NSError(domain: "CalendarError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Event not found with ID \(identifier)"])
        }
        
        if let newTitle = newTitle, !newTitle.isEmpty {
            event.title = newTitle
        }
        if let startStr = startStr, let start = parseDate(startStr) {
            event.startDate = start
        }
        if let endStr = endStr, let end = parseDate(endStr) {
            event.endDate = end
        }
        
        try eventStore.save(event, span: .thisEvent)
        return CalendarEventInfo(ekEvent: event)
    }
    
    // deleteEvent
    func deleteEvent(identifier: String) throws -> Bool {
        guard let event = eventStore.event(withIdentifier: identifier) else {
            throw NSError(domain: "CalendarError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Event not found with ID \(identifier)"])
        }
        try eventStore.remove(event, span: .thisEvent)
        return true
    }
    
    // Open Apple Calendar app
    func openCalendarApp(for date: Date? = nil) {
        if let date = date {
            let interval = date.timeIntervalSinceReferenceDate
            if let url = URL(string: "calshow:\(interval)") {
                NSWorkspace.shared.open(url)
                return
            }
        }
        if let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        }
    }
}

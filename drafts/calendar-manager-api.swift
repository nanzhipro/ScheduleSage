import EventKit

public class CalendarManager {
    private let eventStore: EKEventStore
    
    public init() {
        self.eventStore = EKEventStore()
    }
    
    // MARK: - Calendar Operations
    
    /// Fetch all available calendars
    /// - Returns: An array of EKCalendar objects
    public func fetchCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
    
    /// Fetch titles of all available calendars
    /// - Returns: An array of calendar titles
    public func fetchCalendarTitles() -> [String] {
        return eventStore.calendars(for: .event).map { $0.title }
    }
    
    /// Create a new calendar
    /// - Parameters:
    ///   - title: The title of the new calendar
    ///   - color: The color for the new calendar
    /// - Returns: The newly created EKCalendar object
    public func createCalendar(title: String, color: CGColor) -> Result<EKCalendar, Error> {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = title
        calendar.cgColor = color
        calendar.source = eventStore.defaultCalendarForNewEvents?.source
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return .success(calendar)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Event Operations
    
    /// Fetch events for a specific date range
    /// - Parameters:
    ///   - startDate: The start date of the range
    ///   - endDate: The end date of the range
    ///   - calendar: The calendar to fetch events from (optional)
    /// - Returns: An array of EKEvent objects
    public func fetchEvents(from startDate: Date, to endDate: Date, in calendar: EKCalendar? = nil) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendar.map { [$0] })
        return eventStore.events(matching: predicate)
    }
    
    /// Fetch event titles for a specific date
    /// - Parameters:
    ///   - date: The date to fetch event titles for
    /// - Returns: An array of event titles
    public func fetchEventTitles(for date: Date) -> [String] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        let events = eventStore.events(matching: predicate)
        return events.map { $0.title }
    }
    
    /// Create a new event
    /// - Parameters:
    ///   - title: The title of the event
    ///   - startDate: The start date of the event
    ///   - endDate: The end date of the event
    ///   - calendar: The calendar to add the event to
    /// - Returns: The newly created EKEvent object
    public func createEvent(title: String, startDate: Date, endDate: Date, in calendar: EKCalendar) -> Result<EKEvent, Error> {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calendar
        
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            return .success(event)
        } catch {
            return .failure(error)
        }
    }
    
    /// Update an existing event
    /// - Parameter event: The event to update
    /// - Returns: A Result indicating success or failure
    public func updateEvent(_ event: EKEvent) -> Result<Void, Error> {
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    /// Delete an event
    /// - Parameter event: The event to delete
    /// - Returns: A Result indicating success or failure
    public func deleteEvent(_ event: EKEvent) -> Result<Void, Error> {
        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Reminder Operations
    
    /// Add a reminder to an event
    /// - Parameters:
    ///   - event: The event to add the reminder to
    ///   - alarmOffset: The time offset for the reminder (in seconds before the event)
    /// - Returns: A Result containing the updated event or an error
    public func addReminder(to event: EKEvent, alarmOffset: TimeInterval) -> Result<EKEvent, Error> {
        let alarm = EKAlarm(relativeOffset: -alarmOffset)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            return .success(event)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Search Operations
    
    /// Search for events matching a query
    /// - Parameters:
    ///   - query: The search query
    ///   - startDate: The start date of the search range
    ///   - endDate: The end date of the search range
    /// - Returns: An array of matching EKEvent objects
    public func searchEvents(matching query: String, from startDate: Date, to endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        return events.filter { $0.title.lowercased().contains(query.lowercased()) }
    }
    
    // MARK: - Permissions
    
    /// Request calendar access
    /// - Parameter completion: A closure to be executed when the request is completed
    public func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestAccess(to: .event) { (granted, error) in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }
}

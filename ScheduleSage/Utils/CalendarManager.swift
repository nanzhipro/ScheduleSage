//
//  CalendarManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import EventKit
import Foundation

public final class CalendarManager {

  // MARK: - Types

  private enum CalendarError: Error {
    case accessDenied
    case sourceNotAvailable
    case invalidCalendarData
  }

  // MARK: - Properties

  private let eventStore: EKEventStore
  private let queue = DispatchQueue(
    label: "com.schedulesage.calendarmanager",
    qos: .userInitiated
  )

  // MARK: - Initialization

  public init() {
    self.eventStore = EKEventStore()
  }

  // MARK: - Calendar Operations

  public func fetchCalendars() -> [EKCalendar] {
    queue.sync {
      eventStore.calendars(for: .event)
    }
  }

  public func fetchCalendarTitles() -> [String] {
    queue.sync {
      eventStore.calendars(for: .event).map { $0.title }
    }
  }

  public func createCalendar(title: String, color: CGColor) -> Result<EKCalendar, Error> {
    queue.sync {
      let calendar = EKCalendar(for: .event, eventStore: eventStore)

      guard let source = eventStore.defaultCalendarForNewEvents?.source else {
        return .failure(CalendarError.sourceNotAvailable)
      }

      calendar.title = title
      calendar.cgColor = color
      calendar.source = source

      do {
        try eventStore.saveCalendar(calendar, commit: true)
        return .success(calendar)
      } catch {
        return .failure(error)
      }
    }
  }

  // MARK: - Event Operations

  public func fetchEvents(
    from startDate: Date,
    to endDate: Date,
    in calendar: EKCalendar? = nil
  ) -> [EKEvent] {
    queue.sync {
      let predicate = eventStore.predicateForEvents(
        withStart: startDate,
        end: endDate,
        calendars: calendar.map { [$0] }
      )
      return eventStore.events(matching: predicate)
    }
  }

  public func fetchEventTitles(for date: Date) -> [String] {
    queue.sync {
      let calendar = Calendar.current
      let startOfDay = calendar.startOfDay(for: date)
      guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
        return []
      }

      let predicate = eventStore.predicateForEvents(
        withStart: startOfDay,
        end: endOfDay,
        calendars: nil
      )
      return eventStore.events(matching: predicate).map { $0.title }
    }
  }

  public func createEvent(
    title: String,
    startDate: Date,
    endDate: Date,
    in calendar: EKCalendar
  ) -> Result<EKEvent, Error> {
    queue.sync {
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
  }

  public func updateEvent(_ event: EKEvent) -> Result<Void, Error> {
    queue.sync {
      do {
        try eventStore.save(event, span: .thisEvent, commit: true)
        return .success(())
      } catch {
        return .failure(error)
      }
    }
  }

  public func deleteEvent(_ event: EKEvent) -> Result<Void, Error> {
    queue.sync {
      do {
        try eventStore.remove(event, span: .thisEvent, commit: true)
        return .success(())
      } catch {
        return .failure(error)
      }
    }
  }

  // MARK: - Reminder Operations

  public func addReminder(
    to event: EKEvent,
    alarmOffset: TimeInterval
  ) -> Result<EKEvent, Error> {
    queue.sync {
      let alarm = EKAlarm(relativeOffset: -alarmOffset)
      event.addAlarm(alarm)

      do {
        try eventStore.save(event, span: .thisEvent, commit: true)
        return .success(event)
      } catch {
        return .failure(error)
      }
    }
  }

  // MARK: - Search Operations

  public func searchEvents(
    matching query: String,
    from startDate: Date,
    to endDate: Date
  ) -> [EKEvent] {
    queue.sync {
      let predicate = eventStore.predicateForEvents(
        withStart: startDate,
        end: endDate,
        calendars: nil
      )
      let events = eventStore.events(matching: predicate)
      return events.filter {
        $0.title.localizedCaseInsensitiveContains(query)
      }
    }
  }

  // MARK: - Permissions

  public func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
    if #available(iOS 17.0, macOS 14.0, *) {
      Task {
        do {
          let granted = try await eventStore.requestFullAccessToEvents()
          DispatchQueue.main.async {
            completion(granted, nil)
          }
        } catch {
          DispatchQueue.main.async {
            completion(false, error)
          }
        }
      }
    } else {
      eventStore.requestAccess(to: .event) { granted, error in
        DispatchQueue.main.async {
          completion(granted, error)
        }
      }
    }
  }
}

// MARK: - Convenience Extensions

extension CalendarManager {

  public func checkAuthorizationStatus() -> Bool {
    if #available(iOS 17.0, macOS 14.0, *) {
      return EKEventStore.authorizationStatus(for: .event) == .fullAccess
    } else {
      #if os(iOS)
      return EKEventStore.authorizationStatus(for: .event) == .authorized
      #else
      return EKEventStore.authorizationStatus(for: .event) == .authorized
      #endif
    }
  }

  public func getDefaultCalendar() -> EKCalendar? {
    eventStore.defaultCalendarForNewEvents
  }
}

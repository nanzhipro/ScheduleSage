//
//  CalendarManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import EventKit
import Foundation

public class CalendarManager {
  private let eventStore = EKEventStore()
  
  // MARK: - Error Types
  
  private enum CalendarError: LocalizedError {
    case accessDenied
    case writeOnlyAccess
    case unknownStatus
    
    var errorDescription: String? {
      switch self {
      case .accessDenied:
        return NSLocalizedString("calendar.error.access_denied",
                               comment: "Error message when calendar access is denied")
      case .writeOnlyAccess:
        return NSLocalizedString("calendar.error.write_only_access",
                               comment: "Error message when only write access is granted")
      case .unknownStatus:
        return NSLocalizedString("calendar.error.unknown_status",
                               comment: "Error message for unknown permission status")
      }
    }
    
    var code: Int {
      switch self {
      case .accessDenied: return 1
      case .writeOnlyAccess: return 2
      case .unknownStatus: return 3
      }
    }
  }
  
  public init() {}
  
  // MARK: - Public Methods
  
  /// 请求日历访问权限
  public func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
    handleAuthorizationStatus(
      onAuthorized: { completion(true, nil) },
      onNotDetermined: {
        self.requestCalendarAccess(completion: completion)
      },
      completion: completion
    )
  }
  
  /// 创建日历事件
  public func createEvent(from model: CalendarEvent, completion: @escaping (Bool, Error?) -> Void) {
    handleAuthorizationStatus(
      onAuthorized: { [weak self] in
        self?.createEventInternal(from: model, completion: completion)
      },
      onNotDetermined: { [weak self] in
        self?.requestAccess { granted, error in
          guard granted else {
            completion(false, error)
            return
          }
          self?.createEventInternal(from: model, completion: completion)
        }
      },
      completion: completion
    )
  }
  
  // MARK: - Private Methods
  
  private func handleAuthorizationStatus(
    onAuthorized: @escaping () -> Void,
    onNotDetermined: @escaping () -> Void,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    let status = EKEventStore.authorizationStatus(for: .event)
    
    switch status {
    case .authorized:
      onAuthorized()
      
    case .notDetermined:
      onNotDetermined()
      
    case .denied, .restricted:
      completion(false, self.makeError(.accessDenied))
      
    case .writeOnly:
      completion(false, self.makeError(.writeOnlyAccess))
      
    @unknown default:
      completion(false, self.makeError(.unknownStatus))
    }
  }
  
  private func requestCalendarAccess(completion: @escaping (Bool, Error?) -> Void) {
    if #available(macOS 14.0, *) {
      eventStore.requestFullAccessToEvents { granted, error in
        DispatchQueue.main.async {
          completion(granted, error)
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
  
  private func makeError(_ error: CalendarError) -> NSError {
    NSError(
      domain: "ScheduleSage.Calendar",
      code: error.code,
      userInfo: [NSLocalizedDescriptionKey: error.errorDescription ?? ""]
    )
  }
  
  /// 内部创建事件方法
  private func createEventInternal(from model: CalendarEvent, completion: @escaping (Bool, Error?) -> Void) {
    guard let calendar = getOrCreateCalendar(named: model.calendarName) else {
      let error = NSError(
        domain: "ScheduleSage.Calendar",
        code: 4,
        userInfo: [
          NSLocalizedDescriptionKey: NSLocalizedString(
            "calendar.error.create_failed",
            comment: "Error message when calendar creation fails"
          )
        ]
      )
      completion(false, error)
      return
    }

    let event = EKEvent(eventStore: eventStore)
    event.calendar = calendar
    event.title = model.title
    event.startDate = model.startDate
    event.endDate = model.endDate
    event.location = model.location
    if let url = model.detailURL {
      event.url = url
    }

    do {
      try eventStore.save(event, span: .thisEvent)
      completion(true, nil)
    } catch {
      completion(false, error)
    }
  }

  /// 获取所有日历
  public func getAllCalendars() -> [EKCalendar] {
    return eventStore.calendars(for: .event)
  }

  /// 获取所有日历名称列表
  public func getAllCalendarNames() -> [String] {
    return getAllCalendars().map { $0.title }
  }

  /// 获取或创建日历
  private func getOrCreateCalendar(named name: String) -> EKCalendar? {
    if let existingCalendar = eventStore.calendars(for: .event)
      .first(where: { $0.title == name })
    {
      return existingCalendar
    }

    let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
    newCalendar.title = name

    if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
      newCalendar.source = localSource
    } else if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
      newCalendar.source = defaultSource
    } else {
      return nil
    }

    do {
      try eventStore.saveCalendar(newCalendar, commit: true)
      return newCalendar
    } catch {
      print("Error creating calendar: \(error)")
      return nil
    }
  }
}

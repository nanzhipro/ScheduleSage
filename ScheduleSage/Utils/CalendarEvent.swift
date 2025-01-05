import Foundation

/**
 日历事件模型，需要标准化，如字段定义，类型定义
 这个模型需要传递给 LLM，用于从文本中提取关键的日历事件字段
 */
public struct CalendarEvent: Codable, Equatable, Identifiable {
  public let id: UUID
  public var title: String
  public var startDate: Date
  public var endDate: Date
  public var location: String?
  public var detailURL: URL?
  public var calendarName: String

  public init(
    id: UUID = UUID(),
    title: String,
    startDate: Date,
    endDate: Date,
    location: String? = nil,
    detailURL: URL? = nil,
    calendarName: String
  ) {
    self.id = id
    self.title = title
    self.startDate = startDate
    self.endDate = endDate
    self.location = location
    self.detailURL = detailURL
    self.calendarName = calendarName
  }

  // Equatable conformance to ensure uniqueness
  public static func == (lhs: CalendarEvent, rhs: CalendarEvent) -> Bool {
    return lhs.id == rhs.id
  }
}

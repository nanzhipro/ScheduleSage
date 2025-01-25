import Foundation

enum PreviewData {
  static let events: [Event] = [
    Event(
      id: "1",
      title: "南知读书会第一期",
      time: "3月25日 周一 14:00-16:00",
      location: "知识星球",
      isRecurring: true,
      calendar: "工作"
    ),
    Event(
      id: "2",
      title: "产品评审会",
      time: "3月26日 周二 10:00-11:30",
      location: "腾讯会议",
      isRecurring: false,
      calendar: "工作"
    ),
    Event(
      id: "3",
      title: "团队周会",
      time: "3月27日 周三 09:30-10:30",
      location: "会议室A",
      isRecurring: true,
      calendar: "工作"
    ),
  ]
  
  static let mockCalendarEvents: [CalendarEvent] = [
    CalendarEvent(
      title: "南知读书会第一期",
      location: "知识星球",
      notes: "第一期读书会讨论主题：Swift并发编程",
      startDate: "2024-03-25 14:00:00",
      endDate: "2024-03-25 16:00:00",
      url: "https://meeting.tencent.com/123",
      calendar: "工作",
      status: "confirmed",
      eventIdentifier: "1",
      remarks: "线上会议，请准时参加"
    ),
    CalendarEvent(
      title: "产品评审会",
      location: "腾讯会议",
      notes: "讨论新功能开发计划",
      startDate: "2024-03-26 10:00:00",
      endDate: "2024-03-26 11:30:00",
      url: "https://meeting.tencent.com/456",
      calendar: "工作",
      status: "confirmed",
      eventIdentifier: "2",
      remarks: "请提前准备演示材料"
    )
  ]
  
  static let mockLLMProcessor: LLMEventProcessor = MockLLMProcessor()
  
  @MainActor
  static let mockPopoverViewModel: PopoverViewModel = {
    let vm = PopoverViewModel()
    // 设置一些预览用的初始状态
    return vm
  }()
}

#if DEBUG
// MARK: - Mock LLM Processor
class MockLLMProcessor: LLMEventProcessor {
  func processContent(_ content: String) async throws -> [CalendarEvent] {
    // 模拟处理延迟
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    return PreviewData.mockCalendarEvents
  }
}

extension Event {
  static var preview: Event {
    PreviewData.events[0]
  }
}
#endif

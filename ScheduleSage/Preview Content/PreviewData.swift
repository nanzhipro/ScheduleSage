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
}

#if DEBUG
extension Event {
  static var preview: Event {
    PreviewData.events[0]
  }
}
#endif

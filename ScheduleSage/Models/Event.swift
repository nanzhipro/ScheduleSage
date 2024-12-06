import Foundation

struct Event: Identifiable {
  let id: String
  let title: String
  let time: String
  let location: String?
  let isRecurring: Bool
  let calendar: String?
}

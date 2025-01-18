import SwiftUI

// MARK: - Constants
private enum Constants {
  enum Card {
    static let height: CGFloat = 134
    static let padding = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    static let cornerRadius: CGFloat = 12
  }
  
  enum Spacing {
    static let title: CGFloat = 8
    static let icon: CGFloat = 16
    static let timeBottom: CGFloat = 12
  }
  
  enum Icon {
    static let size: CGFloat = 32
    static let spacing: CGFloat = 8
  }
  
  enum Selection {
    static let size: CGFloat = 16
    static let innerSize: CGFloat = 8
    static let outerOpacity: Double = 0.1
  }
}

// MARK: - Event Card
struct EventCard: View {
  let title: String
  let time: String
  let location: String?
  let calendar: String?
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    HStack(alignment: .center, spacing: Constants.Spacing.icon) {
      CardContent(
        title: title,
        time: time,
        location: location,
        calendar: calendar
      )
      
      Spacer(minLength: Constants.Spacing.icon)
      
      SelectionIndicator(isSelected: isSelected)
        .onTapGesture(perform: onSelect)
    }
    .padding(Constants.Card.padding)
    .frame(height: Constants.Card.height)
    .cardStyle()
  }
}

// MARK: - Supporting Views
private struct CardContent: View {
  let title: String
  let time: String
  let location: String?
  let calendar: String?
  
  var body: some View {
    VStack(alignment: .leading, spacing: Constants.Spacing.title) {
      Text(title)
        .font(.system(size: 17, weight: .medium))
        .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        .lineLimit(1)
      
      Text(time)
        .font(.system(size: 15))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .padding(.bottom, Constants.Spacing.timeBottom)
      
      IconLabels(location: location, calendar: calendar)
    }
  }
}

private struct IconLabels: View {
  let location: String?
  let calendar: String?
  
  var body: some View {
    HStack(spacing: Constants.Spacing.icon) {
      if let location {
        EventIconLabel(icon: "location.fill", text: location)
      }
      if let calendar {
        EventIconLabel(icon: "calendar", text: calendar)
      }
    }
  }
}

private struct EventIconLabel: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: Constants.Icon.spacing) {
      ZStack {
        Circle()
          .fill(ScheduleDesignSystem.Colors.lightGray)
          .frame(width: Constants.Icon.size, height: Constants.Icon.size)
        
        Image(systemName: icon)
          .foregroundColor(ScheduleDesignSystem.Colors.iconGray)
      }
      
      Text(text)
        .font(.system(size: 13))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
    }
  }
}

private struct SelectionIndicator: View {
  let isSelected: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(ScheduleDesignSystem.Colors.success.opacity(Constants.Selection.outerOpacity))
        .frame(width: Constants.Selection.size, height: Constants.Selection.size)

      if isSelected {
        Circle()
          .fill(ScheduleDesignSystem.Colors.success)
          .frame(width: Constants.Selection.innerSize, height: Constants.Selection.innerSize)
      }
    }
  }
}

// MARK: - Style Extensions
private extension View {
  func cardStyle() -> some View {
    self
      .background(ScheduleDesignSystem.Colors.background)
      .cornerRadius(Constants.Card.cornerRadius)
      .scheduleCardStyle()
  }
}

// MARK: - Preview
#if DEBUG
struct EventCard_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      makePreview()
        .previewDisplayName("Light Mode")
      
      makePreview()
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
    .padding()
    .previewLayout(.sizeThatFits)
  }
  
  private static func makePreview() -> some View {
    EventCard(
      title: "南知读书会第一期",
      time: "3月25日 周一 14:00-16:00",
      location: "知识星球",
      calendar: "工作",
      isSelected: true,
      onSelect: {}
    )
  }
}
#endif

import SwiftUI

// MARK: - Constants
private enum Constants {
  enum Card {
    static let height: CGFloat = 154
    static let padding = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    static let cornerRadius: CGFloat = 12
  }
  
  enum Spacing {
    static let title: CGFloat = 8
    static let icon: CGFloat = 16
    static let timeBottom: CGFloat = 8
    static let timeSection: CGFloat = 12
    static let timeIconWidth: CGFloat = 24
    static let separatorPadding: CGFloat = 4
  }
  
  enum Icon {
    static let size: CGFloat = 32
    static let spacing: CGFloat = 8
    static let timeIconSize: CGFloat = 14
  }
  
  enum Time {
    static let separatorWidth: CGFloat = 1
    static let separatorHeight: CGFloat = 24
    static let iconOffset: CGFloat = 2
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
  let startDate: Date
  let endDate: Date
  let location: String?
  let calendar: String?
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    HStack(alignment: .center, spacing: Constants.Spacing.icon) {
      CardContent(
        title: title,
        startDate: startDate,
        endDate: endDate,
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
  let startDate: Date
  let endDate: Date
  let location: String?
  let calendar: String?
  
  var body: some View {
    VStack(alignment: .leading, spacing: Constants.Spacing.title) {
      Text(title)
        .font(.system(size: 17, weight: .medium))
        .foregroundColor(DesignSystem.Colors.primaryText)
        .lineLimit(1)
      
      TimeSection(startDate: startDate, endDate: endDate)
        .padding(.bottom, Constants.Spacing.timeSection)
      
      IconLabels(location: location, calendar: calendar)
    }
  }
}

private struct TimeSection: View {
  let startDate: Date
  let endDate: Date
  
  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      VStack {
        Rectangle()
          .fill(DesignSystem.Colors.borderGray)
          .frame(width: Constants.Time.separatorWidth, height: Constants.Time.separatorHeight)
          .padding(.vertical, Constants.Spacing.separatorPadding)
      }
      .padding(.leading, 4)
      
      VStack(alignment: .leading, spacing: Constants.Spacing.timeBottom) {
        Text(DateFormatters.display.string(from: startDate))
          .font(DesignSystem.Typography.bodyRegular)
          .foregroundColor(DesignSystem.Colors.primaryText)
        
        Text(DateFormatters.display.string(from: endDate))
          .font(DesignSystem.Typography.bodyRegular)
          .foregroundColor(DesignSystem.Colors.primaryText)
      }
      .padding(.leading, Constants.Icon.spacing)
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
          .fill(DesignSystem.Colors.lightGray)
          .frame(width: Constants.Icon.size, height: Constants.Icon.size)
        
        Image(systemName: icon)
          .foregroundColor(DesignSystem.Colors.iconGray)
      }
      
      Text(text)
        .font(DesignSystem.Typography.bodyRegular)
        .foregroundColor(DesignSystem.Colors.secondaryText)
    }
  }
}

private struct SelectionIndicator: View {
  let isSelected: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(DesignSystem.Colors.primary.opacity(Constants.Selection.outerOpacity))
        .frame(width: Constants.Selection.size, height: Constants.Selection.size)

      if isSelected {
        Circle()
          .fill(DesignSystem.Colors.primary)
          .frame(width: Constants.Selection.innerSize, height: Constants.Selection.innerSize)
      }
    }
  }
}

// MARK: - Style Extensions
private extension View {
  func cardStyle() -> some View {
    self
      .background(DesignSystem.Colors.background)
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
      startDate: Date(timeIntervalSince1970: 1679725200),
      endDate: Date(timeIntervalSince1970: 1679732400),
      location: "知识星球",
      calendar: "工作",
      isSelected: true,
      onSelect: {}
    )
  }
}
#endif

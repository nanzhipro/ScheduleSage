import SwiftUI

// MARK: - Constants
private enum EventCardConstants {
  static let cardHeight: CGFloat = 134
  static let cardPadding: EdgeInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20)
  static let titleSpacing: CGFloat = 8
  static let iconSpacing: CGFloat = 16
  static let iconSize: CGFloat = 32
  static let selectionIndicatorSize: CGFloat = 16
  static let selectionIndicatorInnerSize: CGFloat = 8
  static let selectionIndicatorOuterOpacity: Double = 0.1
}

// 日程卡片
struct EventCard: View {
  // MARK: - Properties
  let title: String
  let time: String
  let location: String?
  let isRecurring: Bool
  let calendar: String?
  let isSelected: Bool
  let onSelect: () -> Void

  // MARK: - Body
  var body: some View {
    VStack(alignment: .leading, spacing: EventCardConstants.titleSpacing) {
      // 标题
      Text(title)
        .font(.system(size: 17, weight: .medium))
        .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        .lineLimit(1)

      // 时间
      Text(time)
        .font(.system(size: 15))
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
        .padding(.bottom, 12)

      // 图标行
      HStack(spacing: EventCardConstants.iconSpacing) {
        if let location = location {
          EventIconLabel(icon: "location.fill", text: location)
        }

        if isRecurring {
          EventIconLabel(icon: "arrow.2.circlepath", text: NSLocalizedString("recurring", comment: ""))
        }

        if let calendar = calendar {
          EventIconLabel(icon: "calendar", text: calendar)
        }

        Spacer()

        // 选择指示器
        SelectionIndicator(isSelected: isSelected)
          .onTapGesture(perform: onSelect)
      }
    }
    .padding(EventCardConstants.cardPadding)
    .frame(height: EventCardConstants.cardHeight)
    .background(ScheduleDesignSystem.Colors.background)
    .cornerRadius(12)
    .shadow(
      color: ScheduleDesignSystem.Shadows.cardShadow.color,
      radius: ScheduleDesignSystem.Shadows.cardShadow.radius,
      x: ScheduleDesignSystem.Shadows.cardShadow.x,
      y: ScheduleDesignSystem.Shadows.cardShadow.y
    )
  }
}

// MARK: - Supporting Views
private struct EventIconLabel: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 8) {
      ZStack {
        Circle()
          .fill(ScheduleDesignSystem.Colors.lightGray)
          .frame(
            width: EventCardConstants.iconSize,
            height: EventCardConstants.iconSize
          )
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
        .fill(ScheduleDesignSystem.Colors.success.opacity(EventCardConstants.selectionIndicatorOuterOpacity))
        .frame(
          width: EventCardConstants.selectionIndicatorSize,
          height: EventCardConstants.selectionIndicatorSize
        )

      if isSelected {
        Circle()
          .fill(ScheduleDesignSystem.Colors.success)
          .frame(
            width: EventCardConstants.selectionIndicatorInnerSize,
            height: EventCardConstants.selectionIndicatorInnerSize
          )
      }
    }
  }
}

// MARK: - Preview
#if DEBUG
struct EventCard_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // 浅色模式预览
      EventCard(
        title: "南知读书会第一期",
        time: "3月25日 周一 14:00-16:00",
        location: "知识星球",
        isRecurring: true,
        calendar: "工作",
        isSelected: true,
        onSelect: {}
      )
      .padding()
      .previewDisplayName("Light Mode")

      // 深色模式预览
      EventCard(
        title: "南知读书会第一期",
        time: "3月25日 周一 14:00-16:00",
        location: "知识星球",
        isRecurring: true,
        calendar: "工作",
        isSelected: true,
        onSelect: {}
      )
      .padding()
      .preferredColorScheme(.dark)
      .previewDisplayName("Dark Mode")
    }
    .previewLayout(.sizeThatFits)
  }
}
#endif

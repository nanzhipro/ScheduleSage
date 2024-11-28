import AppKit
import SwiftUI

struct PopoverView: View {
  @State private var remainingUses: Int = 12

  var body: some View {
    VStack(spacing: 0) {
      // 顶部状态栏
      HStack {
        // Pro 状态
        HStack(spacing: ScheduleDesignSystem.Spacing.elementSpacing) {
          ZStack {
            Circle()
              .fill(ScheduleDesignSystem.Colors.lightGray)
              .frame(
                width: ScheduleDesignSystem.Dimensions.crownIconSize,
                height: ScheduleDesignSystem.Dimensions.crownIconSize
              )
            Image(systemName: "crown")
              .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
          }
          Text(String(format: NSLocalizedString("remaining_uses", comment: ""), remainingUses))
            .font(ScheduleDesignSystem.Typography.statusText)
            .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
          Text(NSLocalizedString("separator", comment: ""))
            .font(ScheduleDesignSystem.Typography.statusText)
            .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
          Text(NSLocalizedString("upgrade_prompt", comment: ""))
            .font(ScheduleDesignSystem.Typography.statusText)
            .foregroundColor(ScheduleDesignSystem.Colors.primaryBlue)
        }
        .padding(.leading, ScheduleDesignSystem.Spacing.headerHorizontalPadding)

        Spacer()

        // 添加按钮
        Button(action: {}) {
          Image(systemName: "plus")
            .foregroundColor(ScheduleDesignSystem.Colors.background)
            .frame(
              width: ScheduleDesignSystem.Dimensions.addButtonSize,
              height: ScheduleDesignSystem.Dimensions.addButtonSize
            )
            .background(ScheduleDesignSystem.Colors.primaryBlue)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, ScheduleDesignSystem.Spacing.headerHorizontalPadding)
      }
      .frame(height: ScheduleDesignSystem.Dimensions.headerHeight)
      .background(ScheduleDesignSystem.Colors.background)
      .cornerRadius(ScheduleDesignSystem.Dimensions.headerCornerRadius)

      // 主要内容区域
      VStack(spacing: ScheduleDesignSystem.Spacing.vertical) {
        // 日历图标
        ZStack {
          Circle()
            .fill(ScheduleDesignSystem.Colors.lightGray)
            .frame(
              width: ScheduleDesignSystem.Dimensions.emptyStateIconSize,
              height: ScheduleDesignSystem.Dimensions.emptyStateIconSize
            )
          Image(systemName: "calendar")
            .font(.system(size: 32))
            .foregroundColor(ScheduleDesignSystem.Colors.iconGray)
        }
        .padding(.top, ScheduleDesignSystem.Spacing.vertical)

        Text(NSLocalizedString("add_schedule_title", comment: ""))
          .font(ScheduleDesignSystem.Typography.emptyStateTitle)
          .foregroundColor(ScheduleDesignSystem.Colors.primaryText)

        // 三种添加方式
        HStack(spacing: ScheduleDesignSystem.Spacing.horizontal) {
          AddMethodButton(
            icon: "doc.on.clipboard",
            text: NSLocalizedString("clipboard_import", comment: "")
          )
          AddMethodButton(
            icon: "plus",
            text: NSLocalizedString("manual_input", comment: "")
          )
          AddMethodButton(
            icon: "square.and.arrow.down",
            text: NSLocalizedString("drag_image", comment: "")
          )
        }
        .padding(.horizontal, ScheduleDesignSystem.Spacing.horizontal)

        Spacer()

        // 导入按钮
        Button(action: {}) {
          Text(NSLocalizedString("import_calendar", comment: ""))
            .font(ScheduleDesignSystem.Typography.buttonLabel)
            .foregroundColor(ScheduleDesignSystem.Colors.background)
            .frame(maxWidth: .infinity)
            .frame(height: ScheduleDesignSystem.Dimensions.buttonHeight)
            .background(ScheduleDesignSystem.Colors.primaryBlue.opacity(0.5))
            .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .padding(ScheduleDesignSystem.Layout.containerPadding)
      }
      .frame(maxWidth: .infinity)
      .background(ScheduleDesignSystem.Colors.containerGray)
    }
    .frame(
      width: ScheduleDesignSystem.Dimensions.containerWidth,
      height: ScheduleDesignSystem.Dimensions.containerHeight
    )
    .background(ScheduleDesignSystem.Colors.background)
    .cornerRadius(ScheduleDesignSystem.Dimensions.containerCornerRadius)
    .shadow(
      color: ScheduleDesignSystem.Shadows.containerShadow.color,
      radius: ScheduleDesignSystem.Shadows.containerShadow.radius,
      x: ScheduleDesignSystem.Shadows.containerShadow.x,
      y: ScheduleDesignSystem.Shadows.containerShadow.y
    )
  }
}

struct AddMethodButton: View {
  let icon: String
  let text: String

  var body: some View {
    VStack {
      ZStack {
        Circle()
          .fill(ScheduleDesignSystem.Colors.lightGray)
          .frame(
            width: ScheduleDesignSystem.Dimensions.methodIconSize,
            height: ScheduleDesignSystem.Dimensions.methodIconSize
          )
        Image(systemName: icon)
          .foregroundColor(ScheduleDesignSystem.Colors.iconGray)
      }
      Text(text)
        .font(ScheduleDesignSystem.Typography.methodLabel)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
    }
  }
}

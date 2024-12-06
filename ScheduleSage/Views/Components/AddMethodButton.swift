//
//  AddMethodButton.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024/03/26.
//

import SwiftUI

struct AddMethodButton: View {
  let icon: String
  let text: String
  let action: (() -> Void)?

  init(
    icon: String,
    text: String,
    action: (() -> Void)? = nil
  ) {
    self.icon = icon
    self.text = text
    self.action = action
  }

  var body: some View {
    Button(action: {
      action?()
    }) {
      VStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: ScheduleDesignSystem.Dimensions.methodIconSize))
          .foregroundColor(ScheduleDesignSystem.Colors.iconGray)

        Text(text)
          .font(ScheduleDesignSystem.Typography.bodyRegular)
          .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
    .withHoverEffect()
  }
}

#if DEBUG
struct AddMethodButton_Previews: PreviewProvider {
  static var previews: some View {
    AddMethodButton(
      icon: "doc.text.fill",
      text: "从剪贴板导入"
    )
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif

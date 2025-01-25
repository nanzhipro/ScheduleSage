//
//  AddMethodButton.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import SwiftUI

struct AddMethodButton: View {
  let icon: String
  let text: String
  let action: (() -> Void)?
  
  @State private var isHovered = false
  
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
          .font(.system(size: DesignSystem.Dimensions.methodIconSize))
          .foregroundColor(isHovered ? DesignSystem.Colors.primary : DesignSystem.Colors.iconGray)
        
        Text(text)
          .font(DesignSystem.Typography.bodyRegular)
          .foregroundColor(DesignSystem.Colors.secondaryText)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
    }
    .buttonStyle(.plain)
    .withHoverEffect(scale: 1.02, brightness: 0)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovered = hovering
      }
    }
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

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
  @State private var isPressed = false
  @Environment(\.colorScheme) private var colorScheme
  
  init(
    icon: String,
    text: String,
    action: (() -> Void)? = nil
  ) {
    self.icon = icon
    self.text = text
    self.action = action
  }
  
  private var iconColor: Color {
    if isHovered {
      return DesignSystem.Colors.primary
    }
    return colorScheme == .dark ? .white : DesignSystem.Colors.iconGray
  }
  
  private var textColor: Color {
    if isHovered {
      return DesignSystem.Colors.primary
    }
    return colorScheme == .dark ? .white : DesignSystem.Colors.secondaryText
  }
  
  var body: some View {
    Button(action: {
      withAnimation(.easeOut(duration: 0.2)) {
        isPressed = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        isPressed = false
        action?()
      }
    }) {
      VStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: DesignSystem.Dimensions.methodIconSize))
          .foregroundColor(iconColor)
        
        Text(text)
          .font(DesignSystem.Typography.bodyRegular)
          .foregroundColor(textColor)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
      .shadow(
        color: isHovered ? DesignSystem.Colors.primary.opacity(0.15) : .clear,
        radius: 6,
        x: 0,
        y: 3
      )
    }
    .buttonStyle(.plain)
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

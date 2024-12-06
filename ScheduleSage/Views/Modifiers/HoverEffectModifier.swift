import SwiftUI

struct HoverEffectModifier: ViewModifier {
  @State private var isHovered = false
  let scale: CGFloat
  let brightness: Double

  init(scale: CGFloat = 1.05, brightness: Double = 0.05) {
    self.scale = scale
    self.brightness = brightness
  }

  func body(content: Content) -> some View {
    content
      .scaleEffect(isHovered ? scale : 1.0)
      .brightness(isHovered ? brightness : 0)
      .animation(.easeInOut(duration: 0.2), value: isHovered)
      .onHover { hovering in
        isHovered = hovering
      }
  }
}

// 方便使用的扩展
extension View {
  func withHoverEffect(
    scale: CGFloat = 1.05,
    brightness: Double = 0.05
  ) -> some View {
    modifier(HoverEffectModifier(scale: scale, brightness: brightness))
  }
}

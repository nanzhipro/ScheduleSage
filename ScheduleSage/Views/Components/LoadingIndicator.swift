import SwiftUI

struct LoadingIndicator: View {
  let type: LoadingType
  @State private var isAnimating = false
  @State private var scale: CGFloat = 0.8
  @State private var opacity: Double = 0

  private let animationDuration: Double = 1.0
  private let spinnerSize: CGFloat = 40
  private let strokeWidth: CGFloat = 4

  var body: some View {
    VStack(spacing: 16) {
      // 加载动画
      ZStack {
        // 背景圆环
        Circle()
          .stroke(
            ScheduleDesignSystem.Colors.lightGray,
            lineWidth: strokeWidth
          )
          .frame(width: spinnerSize, height: spinnerSize)

        // 旋转的圆弧
        Circle()
          .trim(from: 0, to: 0.7)
          .stroke(
            ScheduleDesignSystem.Colors.primary,
            lineWidth: strokeWidth
          )
          .frame(width: spinnerSize, height: spinnerSize)
          .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
      }

      // 加载文本
      Text(type.message)
        .font(ScheduleDesignSystem.Typography.bodyRegular)
        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: ScheduleDesignSystem.Dimensions.cardCornerRadius)
        .fill(Color.white)
        .shadow(
          color: Color.black.opacity(0.1),
          radius: 10,
          x: 0,
          y: 4
        )
    )
    .scaleEffect(scale)
    .opacity(opacity)
    .onAppear {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
        scale = 1.0
        opacity = 1.0
      }

      withAnimation(
        Animation
          .linear(duration: animationDuration)
          .repeatForever(autoreverses: false)
      ) {
        isAnimating = true
      }
    }
    .onDisappear {
      withAnimation(.easeOut(duration: 0.2)) {
        scale = 0.8
        opacity = 0
      }
    }
  }
}

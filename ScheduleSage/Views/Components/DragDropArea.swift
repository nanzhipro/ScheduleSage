import SwiftUI

struct DragDropArea<Content: View>: View {
  let content: Content
  @Binding var isDragging: Bool
  @Binding var isOCRProcessing: Bool
  let onDrop: ([URL]) -> Void
  let onDragEntered: () -> Void
  let onDragExited: () -> Void
  @Environment(\.colorScheme) private var colorScheme

  init(
    isDragging: Binding<Bool>,
    isOCRProcessing: Binding<Bool>,
    onDrop: @escaping ([URL]) -> Void,
    onDragEntered: @escaping () -> Void,
    onDragExited: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self._isDragging = isDragging
    self._isOCRProcessing = isOCRProcessing
    self.onDrop = onDrop
    self.onDragEntered = onDragEntered
    self.onDragExited = onDragExited
  }

  var body: some View {
    ZStack {
      // 渐变背景，仅在浅色模式下显示
      if colorScheme == .light {
        LinearGradient(
          colors: [
            DesignSystem.Colors.primary.opacity(0.1),
            DesignSystem.Colors.primary.opacity(0.05),
            DesignSystem.Colors.background
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()
      }
      
      // 主要内容
      content

      // 虚线边框
      RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
        .strokeBorder(
          style: StrokeStyle(
            lineWidth: 2,
            dash: [4, 4]
          )
        )
        .foregroundColor(isDragging ? DesignSystem.Colors.primary : DesignSystem.Colors.borderGray)
        .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
        .padding(.vertical, DesignSystem.Layout.containerPadding.top)
        .animation(.easeInOut(duration: 0.3), value: isDragging)
    }
    .background(colorScheme == .dark ? DesignSystem.Colors.background : nil)
    .onDrop(
      of: [.fileURL],
      delegate: ImageDropDelegate(
        onDrop: onDrop,
        onEntered: onDragEntered,
        onExited: onDragExited,
        onOCRStateChange: { processing in
          isOCRProcessing = processing
        }
      )
    )
  }
}

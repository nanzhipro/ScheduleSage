//
//  DragDropArea.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

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
      // 主要内容
      content
        .zIndex(1)
      
      // 边框效果
      RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
        .strokeBorder(
          isDragging ? 
            DesignSystem.Colors.primary.opacity(0.3) : 
            Color(.separatorColor),
          lineWidth: isDragging ? 3 : 0
        )
        .background(
          RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
            .fill(.ultraThinMaterial.opacity(0.5))
        )
        .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
        .padding(.vertical, DesignSystem.Layout.containerPadding.top / 2)
        .animation(.easeInOut(duration: 0.3), value: isDragging)
        .zIndex(0)
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

//
//  DragDropArea.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import SwiftUI
import UniformTypeIdentifiers

/// 拖放区域组件
/// 提供一个可以接收文件拖放的区域，支持高亮显示拖放状态
struct DragDropArea<Content: View>: View {
  let content: Content
  @Binding var isDragging: Bool
  @Binding var isOCRProcessing: Bool
  let onDrop: ([URL]) -> Void
  let onDragEntered: () -> Void
  let onDragExited: () -> Void
  @Environment(\.colorScheme) private var colorScheme
  @State private var isHovered = false

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
      RoundedRectangle(cornerRadius: 16)
        .strokeBorder(
          isDragging ? 
            DesignSystem.Colors.primary.opacity(0.4) : 
            Color(.separatorColor).opacity(0),
          lineWidth: isDragging ? 2 : 0.5
        )
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Material.ultraThinMaterial)
            .opacity(isDragging ? 1 : 0.5)
        )
        .overlay(
          // 拖放提示效果
          ZStack {
            if isDragging {
              RoundedRectangle(cornerRadius: 16)
                .fill(
                  RadialGradient(
                    gradient: Gradient(colors: [
                      DesignSystem.Colors.primary.opacity(0.08),
                      .clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                  )
                )
            }
          }
        )
        .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
        .padding(.vertical, DesignSystem.Layout.containerPadding.top / 2)
        .animation(.easeInOut(duration: 0.3), value: isDragging)
        .zIndex(0)
    }
    .background(colorScheme == .dark ? DesignSystem.Colors.background : nil)
    // 使用 allowsHitTesting 确保即使窗口失去焦点也能保持交互性
    .allowsHitTesting(true)
    .onHover { hovering in
      isHovered = hovering
    }
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

/// 图片拖放代理
struct ImageDropDelegate: DropDelegate {
  let onDrop: ([URL]) -> Void
  let onEntered: () -> Void
  let onExited: () -> Void
  let onOCRStateChange: (Bool) -> Void
  
  func validateDrop(info: DropInfo) -> Bool {
    return info.hasItemsConforming(to: [.fileURL])
  }
  
  func dropEntered(info: DropInfo) {
    onEntered()
  }
  
  func dropExited(info: DropInfo) {
    onExited()
  }
  
  func performDrop(info: DropInfo) -> Bool {
    guard info.hasItemsConforming(to: [.fileURL]) else {
      return false
    }
    
    let items = info.itemProviders(for: [.fileURL])
    guard !items.isEmpty else {
      return false
    }
    
    var urls: [URL] = []
    let group = DispatchGroup()
    
    for item in items {
      group.enter()
      
      item.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
        defer { group.leave() }
        
        guard error == nil,
              let urlData = urlData as? Data,
              let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
          return
        }
        
        urls.append(url)
      }
    }
    
    group.notify(queue: .main) {
      if !urls.isEmpty {
        onOCRStateChange(true)
        onDrop(urls)
      }
    }
    
    return true
  }
}

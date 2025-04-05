//
//  WindowBlurBackground.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-20.
//

import SwiftUI

/// 窗口毛玻璃背景 - 确保窗口整体有毛玻璃效果
public struct WindowBlurBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  public init() {}

  public var body: some View {
    if #available(macOS 12.0, *) {
      Rectangle()
        .fill(Material.ultraThinMaterial)
        .ignoresSafeArea()
        .opacity(0.1)
    } else {
      VisualEffectView(
        material: .windowBackground,
        blendingMode: .behindWindow
      )
      .ignoresSafeArea()
    }
  }
}

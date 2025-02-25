//
//  SSGradientBackground.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 渐变背景组件
/// 提供一个可配置的渐变背景，支持不同的颜色模式
struct SSGradientBackground: View {
  // 渐变颜色数组
  let colors: [Color]
  // 渐变起点
  let startPoint: UnitPoint
  // 渐变终点
  let endPoint: UnitPoint
  // 是否仅在浅色模式下显示
  let onlyInLightMode: Bool
  
  @Environment(\.colorScheme) private var colorScheme
  
  /// 初始化渐变背景
  /// - Parameters:
  ///   - colors: 渐变颜色数组
  ///   - startPoint: 渐变起点
  ///   - endPoint: 渐变终点
  ///   - onlyInLightMode: 是否仅在浅色模式下显示
  init(
    colors: [Color],
    startPoint: UnitPoint = .top,
    endPoint: UnitPoint = .bottom,
    onlyInLightMode: Bool = true
  ) {
    self.colors = colors
    self.startPoint = startPoint
    self.endPoint = endPoint
    self.onlyInLightMode = onlyInLightMode
  }
  
  /// 使用主题色创建渐变背景
  /// - Parameters:
  ///   - startOpacity: 起始透明度
  ///   - endOpacity: 结束透明度
  ///   - onlyInLightMode: 是否仅在浅色模式下显示
  init(
    primaryColorWithStartOpacity startOpacity: Double = 0.2,
    endOpacity: Double = 0.0,
    onlyInLightMode: Bool = true
  ) {
    self.colors = [
      DesignSystem.Colors.primary.opacity(startOpacity),
      DesignSystem.Colors.primary.opacity((startOpacity + endOpacity) / 2),
      DesignSystem.Colors.background.opacity(endOpacity)
    ]
    self.startPoint = .top
    self.endPoint = .bottom
    self.onlyInLightMode = onlyInLightMode
  }
  
  var body: some View {
    if !onlyInLightMode || colorScheme == .light {
      LinearGradient(
        colors: colors,
        startPoint: startPoint,
        endPoint: endPoint
      )
      .ignoresSafeArea()
    }
  }
}

#if DEBUG
struct SSGradientBackground_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Text("Content")
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      SSGradientBackground(primaryColorWithStartOpacity: 0.2)
    )
    .previewDisplayName("Light Mode")
    
    VStack {
      Text("Content")
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      SSGradientBackground(
        colors: [.blue.opacity(0.3), .purple.opacity(0.1)],
        onlyInLightMode: false
      )
    )
    .environment(\.colorScheme, .dark)
    .previewDisplayName("Dark Mode")
  }
}
#endif 
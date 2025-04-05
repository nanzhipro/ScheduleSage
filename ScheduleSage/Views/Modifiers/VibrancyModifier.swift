//
//  VibrancyModifier.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-04-02.
//

import SwiftUI

/// 磨砂玻璃效果修饰符
/// 为视图添加macOS风格的磨砂玻璃效果，提升视觉层次感
/// 支持自定义材质类型、透明度和圆角
struct VibrancyModifier: ViewModifier {
  // 材质类型：标准(适合大多数UI)、薄(适合背景)、超薄(适合悬浮元素)
  enum MaterialType {
    case standard, thin, ultraThin

    @available(macOS 12.0, *)
    var material: Material {
      switch self {
      case .standard: return .regularMaterial
      case .thin: return .thinMaterial
      case .ultraThin: return .ultraThinMaterial
      }
    }

    // 为不同材质类型提供不同的背景颜色和透明度
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
      switch (self, colorScheme) {
      case (.standard, .dark):
        return DesignSystem.Colors.cardBackground
      case (.standard, .light):
        return Color.white
      case (.thin, .dark):
        return DesignSystem.Colors.background
      case (.thin, .light):
        return Color.white.opacity(0.85)
      case (.ultraThin, .dark):
        return DesignSystem.Colors.background.opacity(0.7)
      case (.ultraThin, .light):
        return Color.white.opacity(0.7)
      @unknown default:
        // 未知情况下的安全回退
        return colorScheme == .dark ? DesignSystem.Colors.background : Color.white.opacity(0.7)
      }
    }

    // 透明度设置 - 简化的实现，删除复杂的渐变
    func opacityValue(for colorScheme: ColorScheme) -> Double {
      switch (self, colorScheme) {
      case (.standard, .dark): return 0.9
      case (.standard, .light): return 0.85
      case (.thin, .dark): return 0.8
      case (.thin, .light): return 0.75
      case (.ultraThin, .dark): return 0.7
      case (.ultraThin, .light): return 0.6
      @unknown default:
        return colorScheme == .dark ? 0.8 : 0.7
      }
    }
  }

  // 配置选项
  let materialType: MaterialType
  let cornerRadius: CGFloat
  let addBorder: Bool
  let opacity: Double

  @Environment(\.colorScheme) private var colorScheme

  init(
    materialType: MaterialType = .ultraThin,
    cornerRadius: CGFloat = DesignSystem.Dimensions.cardCornerRadius,
    addBorder: Bool = true,
    opacity: Double = 1.0
  ) {
    self.materialType = materialType
    self.cornerRadius = cornerRadius
    self.addBorder = addBorder
    self.opacity = opacity
  }

  func body(content: Content) -> some View {
    content
      .background(
        ZStack {
          // 材质层
          if #available(macOS 12.0, *) {
            // 基础背景层 - 提供透明度基础
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(
                colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.3)
              )

            // 毛玻璃效果层
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(materialType.material)
              .opacity(opacity)
          } else {
            // 旧版macOS回退方案 - 简化实现
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(materialType.backgroundColor(for: colorScheme))
              .opacity(opacity * materialType.opacityValue(for: colorScheme))
          }

          // 可选边框
          if addBorder {
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(
                colorScheme == .dark
                  ? DesignSystem.Colors.primary.opacity(0.12)
                  : DesignSystem.Colors.primary.opacity(0.08),
                lineWidth: 0.5
              )
          }
        }
      )
  }
}

// 为View添加扩展方法，使修饰符更容易使用
extension View {
  /// 为视图添加磨砂玻璃效果
  /// - Parameters:
  ///   - materialType: 材质类型(.standard, .thin, .ultraThin)
  ///   - cornerRadius: 圆角半径
  ///   - addBorder: 是否添加细微边框
  ///   - opacity: 透明度
  /// - Returns: 添加了磨砂玻璃效果的视图
  func withVibrancy(
    materialType: VibrancyModifier.MaterialType = .ultraThin,
    cornerRadius: CGFloat = DesignSystem.Dimensions.cardCornerRadius,
    addBorder: Bool = true,
    opacity: Double = 1.0
  ) -> some View {
    modifier(
      VibrancyModifier(
        materialType: materialType,
        cornerRadius: cornerRadius,
        addBorder: addBorder,
        opacity: opacity
      )
    )
  }

  /// 条件性地应用给定的转换
  /// - Parameters:
  ///   - condition: 判断是否应用转换的条件
  ///   - transform: 要应用的转换闭包
  /// - Returns: 根据条件转换后的视图
  @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

/// 视觉效果视图 - 用于支持需要原生NSVisualEffectView的情况
struct VisualEffectView: NSViewRepresentable {
  let material: NSVisualEffectView.Material
  let blendingMode: NSVisualEffectView.BlendingMode

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

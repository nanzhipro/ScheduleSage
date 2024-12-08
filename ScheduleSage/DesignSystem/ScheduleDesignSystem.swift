import SwiftUI

// MARK: - Theme Type
enum ThemeType {
  case apple  // 苹果风格
  case wechat  // 微信风格
}

// MARK: - Design System
enum ScheduleDesignSystem {
  // 当前主题
  static var currentTheme: ThemeType = .wechat

  // MARK: - Colors
  enum Colors {
    // Brand Colors
    static var primary: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "007AFF", dark: "0A84FF")  // 苹果蓝
      case .wechat:
        return Color(light: "07C160", dark: "07C160")  // 微信绿
      }
    }

    static var primaryBackground: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "F5F5F7", dark: "242424")
      case .wechat:
        return Color(light: "F7F7F7", dark: "242424")
      }
    }

    // Base Colors
    static var background: Color {
      Color(light: "FFFFFF", dark: "1E1E1E")
    }

    static var secondaryGray: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "86868B", dark: "98989F")
      case .wechat:
        return Color(light: "9B9B9B", dark: "98989F")
      }
    }

    static var lightGray: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "F2F2F7", dark: "2C2C2E")
      case .wechat:
        return Color(light: "F7F7F7", dark: "2C2C2E")
      }
    }

    static var containerGray: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "F8F8FA", dark: "333333")
      case .wechat:
        return Color(light: "F8F8F8", dark: "333333")
      }
    }

    static var borderGray: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "E5E5E5", dark: "424242")
      case .wechat:
        return Color(light: "EBEDF0", dark: "424242")
      }
    }

    static var success: Color { primary }

    // Text Colors
    static var primaryText: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "000000", dark: "FFFFFF")
      case .wechat:
        return Color(light: "2C2C2C", dark: "FFFFFF")
      }
    }

    static var secondaryText: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "86868B", dark: "98989F")
      case .wechat:
        return Color(light: "9B9B9B", dark: "98989F")
      }
    }

    static var tertiaryText: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "C7C7CC", dark: "48484A")
      case .wechat:
        return Color(light: "BFBFBF", dark: "48484A")
      }
    }

    // Button Colors
    static var cancelButtonBackground: Color {
      switch currentTheme {
      case .apple:
        return Color(hex: "F5F5F5")
      case .wechat:
        return Color(hex: "F7F7F7")
      }
    }

    // Icon Colors
    static var iconGray: Color {
      switch currentTheme {
      case .apple:
        return Color(hex: "666666")
      case .wechat:
        return Color(hex: "8F8F8F")
      }
    }

    // Link Colors
    static var link: Color {
      switch currentTheme {
      case .apple:
        return Color(hex: "007AFF")
      case .wechat:
        return Color(hex: "576B95")
      }
    }

    // 主要背景色
    static var secondaryBackground: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "FFFFFF", dark: "2C2C2C")
      case .wechat:
        return Color(light: "FFFFFF", dark: "2C2C2C")
      }
    }

    // 卡片背景色
    static var cardBackground: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "FFFFFF", dark: "2A2A2A")
      case .wechat:
        return Color(light: "FFFFFF", dark: "2A2A2A")
      }
    }

    // 悬停状态背景色
    static var hoverBackground: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "F5F5F7", dark: "3A3A3A")
      case .wechat:
        return Color(light: "F7F7F7", dark: "3A3A3A")
      }
    }

    // 分割线颜色
    static var separator: Color {
      switch currentTheme {
      case .apple:
        return Color(light: "E5E5E5", dark: "3D3D3D")
      case .wechat:
        return Color(light: "EBEDF0", dark: "3D3D3D")
      }
    }
  }

  // MARK: - Typography
  enum Typography {
    // Headers
    static let headerTitle = Font.system(size: 17, weight: .medium)

    // Content
    static var bodyLarge = Font.system(size: 15)
    static var bodyRegular: Font {
      switch currentTheme {
      case .apple:
        return .system(size: 13)
      case .wechat:
        return .system(size: 14)
      }
    }
    static let bodyMedium = Font.system(size: 14, weight: .medium)

    // Labels
    static let formLabel = Font.system(size: 14)
    static let buttonLabel = Font.system(size: 15)

    // Event Related
    static let eventTitle = Font.system(size: 16, weight: .medium)
    static let eventTime = Font.system(size: 14)
    static let eventCount = Font.system(size: 13)

    // Status
    static let statusText = Font.system(size: 13)
    static let emptyStateTitle = Font.system(size: 15, weight: .medium)
    static let methodLabel = Font.system(size: 13)

    // 添加 caption 样式
    static let caption = Font.system(size: 12, weight: .regular)

    // 更新标题字体
    static let title = Font.system(size: 24, weight: .semibold)

    // 导航相关
    static let navigationText = Font.system(size: 13, weight: .medium)
  }

  // MARK: - Dimensions
  enum Dimensions {
    // Container Sizes
    static let containerWidth: CGFloat = 440
    static let containerHeight: CGFloat = 563  // 增加 20 以适应更大的上边距
    static let confirmPageHeight: CGFloat = 550

    // Corner Radii
    static let containerCornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 8
    static let buttonCornerRadius: CGFloat = 8
    static let headerCornerRadius: CGFloat = 8

    // Component Heights
    static let headerHeight: CGFloat = 56  // 原来是 44，增加以适应更大的上边距
    static let formFieldHeight: CGFloat = 44
    static let buttonHeight: CGFloat = 44
    static let listHeaderHeight: CGFloat = 44

    // Icon Sizes
    static let statusIconSize: CGFloat = 24
    static let methodIconSize: CGFloat = 32
    static let addButtonSize: CGFloat = 28
    static let crownIconSize: CGFloat = 24
    static let emptyStateIconSize: CGFloat = 80
    static let eventIconSize: CGFloat = 32

    // Event Card
    static let eventCardHeight: CGFloat = 134
    static let eventCardSpacing: CGFloat = 12
    static let selectionIndicatorOuterSize: CGFloat = 16
    static let selectionIndicatorInnerSize: CGFloat = 8

    // List Layout
    static let listContentSpacing: CGFloat = 16
    static let listVerticalPadding: CGFloat = 20

    // Settings Button
    static let settingsButtonSize: CGFloat = 22
  }

  // MARK: - Spacing
  enum Spacing {
    // General
    static let horizontal: CGFloat = 24
    static let vertical: CGFloat = 24
    static let iconSpacing: CGFloat = 8
    static let elementSpacing: CGFloat = 16

    // Form
    static let formFieldSpacing: CGFloat = 24
    static let contentPadding: CGFloat = 16

    // Header
    static let headerHorizontalPadding: CGFloat = 24

    // Event Card
    static let eventCardPadding: CGFloat = 20
    static let eventIconSpacing: CGFloat = 16

    // List
    static let listHeaderPadding: CGFloat = 24
    static let listContentPadding: CGFloat = 24
  }

  // MARK: - Shadows
  enum Shadows {
    static var containerShadow: Shadow {
      switch currentTheme {
      case .apple:
        return Shadow(
          color: .black.opacity(colorScheme == .dark ? 0.3 : 0.12),
          radius: 8,
          x: 0,
          y: 2
        )
      case .wechat:
        return Shadow(
          color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05),
          radius: 6,
          x: 0,
          y: 2
        )
      }
    }

    static var cardShadow: Shadow {
      switch currentTheme {
      case .apple:
        return Shadow(
          color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05),
          radius: 2,
          x: 0,
          y: 1
        )
      case .wechat:
        return Shadow(
          color: .black.opacity(colorScheme == .dark ? 0.3 : 0.03),
          radius: 2,
          x: 0,
          y: 1
        )
      }
    }

    private static var colorScheme: ColorScheme {
      @Environment(\.colorScheme) var colorScheme
      return colorScheme
    }
  }

  // MARK: - Layout
  enum Layout {
    static let formFieldPadding = EdgeInsets(
      top: 16,
      leading: 16,
      bottom: 16,
      trailing: 16
    )

    static let containerPadding = EdgeInsets(
      top: 40,  // 原来是 20，现在翻倍
      leading: 20,
      bottom: 20,
      trailing: 20
    )

    // 新增状态栏内边距
    static let statusBarPadding = EdgeInsets(
      top: 12,  // 状态栏专用上边距
      leading: 20,
      bottom: 8,
      trailing: 20
    )
  }
}

// MARK: - Helper Structures
struct Shadow {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

// MARK: - Helper Extensions
extension Color {
  init(light: String, dark: String) {
    let lightColor = NSColor(hex: light)
    let darkColor = NSColor(hex: dark)
    self.init(
      nsColor: NSColor(name: nil) { appearance in
        switch appearance.name {
        case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua:
          return darkColor
        default:
          return lightColor
        }
      }
    )
  }

  init(hex: String) {
    self.init(nsColor: NSColor(hex: hex))
  }
}

// MARK: - NSColor Extension
extension NSColor {
  convenience init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      calibratedRed: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      alpha: Double(a) / 255
    )
  }
}

// MARK: - View Modifiers
extension View {
  func scheduleCardStyle() -> some View {
    self
      .background(ScheduleDesignSystem.Colors.background)
      .cornerRadius(ScheduleDesignSystem.Dimensions.cardCornerRadius)
      .shadow(
        color: ScheduleDesignSystem.Shadows.cardShadow.color,
        radius: ScheduleDesignSystem.Shadows.cardShadow.radius,
        x: ScheduleDesignSystem.Shadows.cardShadow.x,
        y: ScheduleDesignSystem.Shadows.cardShadow.y
      )
  }

  func scheduleFormFieldStyle() -> some View {
    self
      .frame(height: ScheduleDesignSystem.Dimensions.formFieldHeight)
      .padding(ScheduleDesignSystem.Layout.formFieldPadding)
      .background(ScheduleDesignSystem.Colors.background)
      .cornerRadius(ScheduleDesignSystem.Dimensions.cardCornerRadius)
      .overlay(
        RoundedRectangle(cornerRadius: ScheduleDesignSystem.Dimensions.cardCornerRadius)
          .stroke(ScheduleDesignSystem.Colors.borderGray, lineWidth: 1)
      )
  }
}

// 提供一个便捷的主题切换方法
extension ScheduleDesignSystem {
  static func switchTheme(to theme: ThemeType) {
    currentTheme = theme
  }
}

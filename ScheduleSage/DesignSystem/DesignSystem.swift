import SwiftUI

/// 外观模式
enum AppearanceMode: String, CaseIterable, Identifiable {
  case light = "light"
  case dark = "dark"
  case auto = "auto"

  var id: String { rawValue }

  var localizedName: String {
    switch self {
    case .light:
      return NSLocalizedString("appearance_light", comment: "Light mode")
    case .dark:
      return NSLocalizedString("appearance_dark", comment: "Dark mode")
    case .auto:
      return NSLocalizedString("appearance_auto", comment: "Auto mode")
    }
  }

  var systemImage: String {
    switch self {
    case .light:
      return "sun.max"
    case .dark:
      return "moon.stars"
    case .auto:
      return "circle.lefthalf.filled"
    }
  }
}

/// 主题类型
/// - apple: 苹果风格，简洁现代
/// - wechat: 微信风格，偏绿色调
/// - airbnb: Airbnb风格，活力红色调
enum ThemeType: String, CaseIterable, Identifiable {
  case apple, wechat, airbnb

  var id: String { rawValue }
}

/// ScheduleSage 应用的设计系统
/// 包含颜色、排版、尺寸、间距、阴影等设计元素
enum DesignSystem {
  /// 当前使用的主题类型，默认为微信风格
  static var currentTheme: ThemeType = .wechat

  // MARK: - Gradients
  /// 渐变配色系统
  enum Gradients {
    /// 主容器渐变背景
    /// 用于主要容器的渐变背景效果，支持深色模式
    static func containerBackground(colorScheme: ColorScheme) -> LinearGradient {
      LinearGradient(
        colors: colorScheme == .dark
          ? [
            Colors.darkGradientTop,  // 深色模式顶部色
            Colors.darkGradientMiddle,  // 深色模式中间色
            Colors.background,  // 深色模式底部色
          ]
          : [
            Colors.lightGradientTop,  // 浅色模式顶部色
            Colors.lightGradientMiddle,  // 浅色模式中间色
            Colors.background,  // 浅色模式底部色
          ],
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  // MARK: - Colors
  /// 颜色系统
  enum Colors {
    /// 品牌主色
    /// - apple: iOS蓝
    /// - wechat: 微信绿
    /// - airbnb: 珊瑚红
    static var primary: Color {
      switch currentTheme {
      case .apple: return Color(light: "007AFF", dark: "0A84FF")
      case .wechat: return Color(light: "07C160", dark: "07C160")
      case .airbnb: return Color(light: "FF5A5F", dark: "FF5A5F")
      }
    }

    /// 次要品牌色
    /// 用于次要强调、辅助元素等
    static var secondary: Color {
      switch currentTheme {
      case .apple: return Color(light: "5856D6", dark: "5E5CE6")
      case .wechat: return Color(light: "576B95", dark: "576B95")
      case .airbnb: return Color(light: "00A699", dark: "00A699")
      }
    }

    /// 主要背景色
    /// 用于应用的主要背景，确保内容清晰可见
    static var primaryBackground: Color {
      switch currentTheme {
      case .apple: return Color(light: "F5F5F7", dark: "242424")
      case .wechat: return Color(light: "F7F7F7", dark: "242424")
      case .airbnb: return Color(light: "F7F7F7", dark: "1D1D1D")
      }
    }

    /// 基础背景色
    /// 用于卡片、弹窗等组件的背景
    static var background: Color {
      let (light, dark) =
        currentTheme == .airbnb
        ? ("FFFFFF", "222222")
        : ("FFFFFF", "1E1E1E")
      return Color(light: light, dark: dark)
    }

    /// 次要灰色
    /// 用于次要信息、图标等
    static var secondaryGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "86868B", dark: "98989F")
      case .wechat: return Color(light: "9B9B9B", dark: "98989F")
      case .airbnb: return Color(light: "717171", dark: "B0B0B0")
      }
    }

    /// 浅灰色
    /// 用于背景、分割线等装饰性元素
    static var lightGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "F2F2F7", dark: "2C2C2E")
      case .wechat: return Color(light: "F7F7F7", dark: "2C2C2E")
      case .airbnb: return Color(light: "F7F7F7", dark: "2D2D2D")
      }
    }

    /// 容器灰色
    /// 用于容器、卡片等组件的背景
    static var containerGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "F8F8FA", dark: "333333")
      case .wechat: return Color(light: "F8F8F8", dark: "333333")
      case .airbnb: return Color(light: "F8F8F8", dark: "2A2A2A")
      }
    }

    /// 边框灰色
    /// 用于边框、分割线等
    static var borderGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "E5E5E5", dark: "424242")
      case .wechat: return Color(light: "EBEDF0", dark: "424242")
      case .airbnb: return Color(light: "DDDDDD", dark: "3D3D3D")
      }
    }

    /// 成功状态颜色
    /// 用于成功提示、完成状态等
    static var success: Color {
      currentTheme == .airbnb
        ? Color(light: "008A05", dark: "00A306")
        : primary
    }

    /// 错误状态颜色
    /// 用于错误提示、警告状态等
    static var error: Color {
      switch currentTheme {
      case .apple: return Color(light: "FF3B30", dark: "FF453A")
      case .wechat: return Color(light: "FA5151", dark: "FA5151")
      case .airbnb: return Color(light: "C13515", dark: "E31C1C")
      }
    }

    /// 主要文本颜色
    /// 用于标题、正文等主要文本
    static var primaryText: Color {
      switch currentTheme {
      case .apple: return Color(light: "000000", dark: "FFFFFF")
      case .wechat: return Color(light: "2C2C2C", dark: "FFFFFF")
      case .airbnb: return Color(light: "222222", dark: "FFFFFF")
      }
    }

    /// 次要文本颜色
    /// 用于描述、说明等次要文本
    static var secondaryText: Color {
      switch currentTheme {
      case .apple: return Color(light: "86868B", dark: "98989F")
      case .wechat: return Color(light: "9B9B9B", dark: "98989F")
      case .airbnb: return Color(light: "717171", dark: "A0A0A0")
      }
    }

    /// 第三级文本颜色
    /// 用于辅助性文本、占位符等
    static var tertiaryText: Color {
      switch currentTheme {
      case .apple: return Color(light: "C7C7CC", dark: "48484A")
      case .wechat: return Color(light: "BFBFBF", dark: "48484A")
      case .airbnb: return Color(light: "BFBFBF", dark: "4A4A4A")
      }
    }

    /// 取消按钮背景色
    /// 用于取消、返回等次要操作按钮
    static var cancelButtonBackground: Color {
      Color(hex: currentTheme == .apple ? "F5F5F5" : "F7F7F7")
    }

    /// 图标灰色
    /// 用于常规状态的图标
    static var iconGray: Color {
      switch currentTheme {
      case .apple: return Color(hex: "666666")
      case .wechat: return Color(hex: "8F8F8F")
      case .airbnb: return Color(hex: "717171")
      }
    }

    /// 链接颜色
    /// 用于可点击的文本链接
    static var link: Color {
      switch currentTheme {
      case .apple: return Color(hex: "007AFF")
      case .wechat: return Color(hex: "576B95")
      case .airbnb: return Color(hex: "FF5A5F")
      }
    }

    /// 次要背景色
    /// 用于次级页面或组件的背景
    static var secondaryBackground: Color {
      Color(light: "FFFFFF", dark: "2C2C2C")
    }

    /// 卡片背景色
    /// 用于卡片组件的背景
    static var cardBackground: Color {
      Color(light: "FFFFFF", dark: "2A2A2A")
    }

    /// 悬停背景色
    /// 用于元素悬停状态
    static var hoverBackground: Color {
      switch currentTheme {
      case .apple: return Color(light: "F5F5F7", dark: "3A3A3A")
      case .wechat: return Color(light: "F7F7F7", dark: "3A3A3A")
      case .airbnb: return Color(light: "F8F8F8", dark: "3A3A3A")
      }
    }

    /// 分割线颜色
    /// 用于列表项分割、边框等
    static var separator: Color {
      switch currentTheme {
      case .apple: return Color(light: "E5E5E5", dark: "3D3D3D")
      case .wechat: return Color(light: "EBEDF0", dark: "3D3D3D")
      case .airbnb: return Color(light: "EBEBEB", dark: "3D3D3D")
      }
    }

    // MARK: - Gradient Colors

    /// 深色模式渐变色 - 顶部
    static let darkGradientTop = Color(
      light: "F5F5F7",  // 浅色模式下不使用
      dark: "151516"  // rgb(21, 21, 22)
    )

    /// 深色模式渐变色 - 中间
    static let darkGradientMiddle = Color(
      light: "F7F7F7",  // 浅色模式下不使用
      dark: "181819"  // rgb(24, 24, 25)
    )

    /// 浅色模式渐变色 - 顶部
    static let lightGradientTop = Color(
      light: "F5F7F8",  // rgb(245, 247, 248)
      dark: "242424"  // 深色模式下不使用
    )

    /// 浅色模式渐变色 - 中间
    static let lightGradientMiddle = Color(
      light: "F7F8F9",  // rgb(247, 248, 249)
      dark: "242424"  // 深色模式下不使用
    )
  }

  // MARK: - Typography
  /// 排版系统
  enum Typography {
    /// 页面标题字体
    /// 用于页面主标题，17pt 中等粗细
    static let headerTitle = Font.system(size: 17, weight: .medium)

    /// 大号正文字体
    /// 用于重要内容，15pt 常规粗细
    static let bodyLarge = Font.system(size: 15)

    /// 常规正文字体
    /// apple主题13pt，其他14pt
    static var bodyRegular: Font {
      .system(size: currentTheme == .apple ? 13 : 14)
    }

    /// 中等正文字体
    /// 用于重要的正文内容，14pt 中等粗细
    static let bodyMedium = Font.system(size: 14, weight: .medium)

    /// 表单标签字体
    /// 用于表单字段标签，14pt
    static let formLabel = Font.system(size: 14)

    /// 按钮文字字体
    /// 用于按钮文字，15pt
    static let buttonLabel = Font.system(size: 15)

    /// 事件标题字体
    /// 用于事件卡片标题，16pt 中等粗细
    static let eventTitle = Font.system(size: 16, weight: .medium)

    /// 事件时间字体
    /// 用于显示事件时间，14pt
    static let eventTime = Font.system(size: 14)

    /// 事件计数字体
    /// 用于显示事件数量，13pt
    static let eventCount = Font.system(size: 13)

    /// 状态文本字体
    /// 用于显示状态信息，13pt
    static let statusText = Font.system(size: 13)

    /// 空状态标题字体
    /// 用于空列表等状态的标题，15pt 中等粗细
    static let emptyStateTitle = Font.system(size: 15, weight: .medium)

    /// 方法标签字体
    /// 用于显示方法名称，13pt
    static let methodLabel = Font.system(size: 13)

    /// 说明文本字体
    /// 用于辅助说明文本，12pt
    static let caption = Font.system(size: 12)

    /// 大标题字体
    /// 用于主要标题，24pt 半粗体
    static let title = Font.system(size: 24, weight: .semibold)

    /// 导航文本字体
    /// 用于导航栏文本，13pt 中等粗细
    static let navigationText = Font.system(size: 13, weight: .medium)

    /// 大页面标题字体
    /// 用于宽页面(640px)的主标题，20pt 半粗体
    static let largeHeaderTitle = Font.system(size: 20, weight: .semibold)

    /// 大页面副标题字体
    /// 用于宽页面的副标题，14pt
    static let largeHeaderSubtitle = Font.system(size: 14)
  }

  // MARK: - Dimensions
  /// 尺寸系统
  enum Dimensions {
    /// 容器宽度
    static let containerWidth: CGFloat = 440
    /// 容器高度
    static let containerHeight: CGFloat = 563
    /// 确认页面高度
    static let confirmPageHeight: CGFloat = 550
    /// 容器圆角半径
    static let containerCornerRadius: CGFloat = 12
    /// 卡片圆角半径
    static let cardCornerRadius: CGFloat = 8
    /// 按钮圆角半径
    static let buttonCornerRadius: CGFloat = 8
    /// 头部圆角半径
    static let headerCornerRadius: CGFloat = 8
    /// 头部高度
    static let headerHeight: CGFloat = 56
    /// 表单字段高度
    static let formFieldHeight: CGFloat = 44
    /// 按钮高度
    static let buttonHeight: CGFloat = 44
    /// 列表头部高度
    static let listHeaderHeight: CGFloat = 44
    /// 状态图标尺寸
    static let statusIconSize: CGFloat = 24
    /// 方法图标尺寸
    static let methodIconSize: CGFloat = 32
    /// 添加按钮尺寸
    static let addButtonSize: CGFloat = 28
    /// 皇冠图标尺寸
    static let crownIconSize: CGFloat = 24
    /// 空状态图标尺寸
    static let emptyStateIconSize: CGFloat = 80
    /// 事件图标尺寸
    static let eventIconSize: CGFloat = 32
    /// 事件卡片高度
    static let eventCardHeight: CGFloat = 134
    /// 事件卡片间距
    static let eventCardSpacing: CGFloat = 12
    /// 选择指示器外圈尺寸
    static let selectionIndicatorOuterSize: CGFloat = 16
    /// 选择指示器中圈尺寸
    static let selectionIndicatorMiddleSize: CGFloat = 12
    /// 选择指示器内圈尺寸
    static let selectionIndicatorInnerSize: CGFloat = 8
    /// 列表内容间距
    static let listContentSpacing: CGFloat = 16
    /// 列表垂直内边距
    static let listVerticalPadding: CGFloat = 20
    /// 设置按钮尺寸
    static let settingsButtonSize: CGFloat = 22

    /// 主页面宽度
    static let mainViewWidth: CGFloat = 900
    /// 主页面高度
    static let mainViewHeight: CGFloat = 600
    /// 事件列表页宽度
    static let eventListWidth: CGFloat = mainViewWidth * 0.8  // 640
    /// 事件列表页高度
    static let eventListHeight: CGFloat = mainViewHeight * 0.8  // 512

    /// 大尺寸方法按钮图标
    static let largeMethodIconSize: CGFloat = 40  // 增大图标尺寸

    /// 大尺寸按钮高度
    static let largeButtonHeight: CGFloat = 52  // 增大按钮高度
  }

  // MARK: - Spacing
  /// 间距系统
  enum Spacing {
    /// 水平间距
    static let horizontal: CGFloat = 24
    /// 垂直间距
    static let vertical: CGFloat = 24
    /// 图标间距
    static let iconSpacing: CGFloat = 8
    /// 元素间距
    static let elementSpacing: CGFloat = 16
    /// 文本间距
    static let textSpacing: CGFloat = 8
    /// 区块间距
    static let sectionSpacing: CGFloat = 16
    /// 表单字段间距
    static let formFieldSpacing: CGFloat = 24
    /// 内容内边距
    static let contentPadding: CGFloat = 16
    /// 头部水平内边距
    static let headerHorizontalPadding: CGFloat = 24
    /// 事件卡片内边距
    static let eventCardPadding: CGFloat = 20
    /// 事件图标间距
    static let eventIconSpacing: CGFloat = 16
    /// 列表头部内边距
    static let listHeaderPadding: CGFloat = 24
    /// 列表内容内边距
    static let listContentPadding: CGFloat = 24
    /// 大页面标题间距
    static let largeHeaderSpacing: CGFloat = 12

    /// 大尺寸内容间距
    static let largeContentSpacing: CGFloat = 32  // 增大内容间距

    /// 大尺寸按钮间距
    static let largeButtonSpacing: CGFloat = 24  // 增大按钮间距
  }

  // MARK: - Shadows
  /// 阴影系统
  enum Shadows {
    /// 获取阴影不透明度
    /// - Parameters:
    ///   - theme: 主题类型
    ///   - isDark: 是否为深色模式
    /// - Returns: 阴影不透明度
    private static func shadowOpacity(for theme: ThemeType, isDark: Bool) -> Double {
      switch theme {
      case .apple: return isDark ? 0.3 : 0.12
      case .wechat: return isDark ? 0.3 : 0.05
      case .airbnb: return isDark ? 0.35 : 0.08
      }
    }

    /// 容器阴影
    /// 用于主要容器的阴影效果
    static func containerShadow(colorScheme: ColorScheme) -> Shadow {
      let isDark = colorScheme == .dark
      let opacity = shadowOpacity(for: currentTheme, isDark: isDark)

      return Shadow(
        color: .black.opacity(opacity),
        radius: currentTheme == .airbnb ? 15 : (currentTheme == .apple ? 8 : 6),
        x: 0,
        y: currentTheme == .airbnb ? 5 : 2
      )
    }

    /// 卡片阴影
    /// 用于卡片组件的阴影效果
    static func cardShadow(colorScheme: ColorScheme) -> Shadow {
      let isDark = colorScheme == .dark
      let opacity =
        currentTheme == .airbnb
        ? (isDark ? 0.35 : 0.06) : (currentTheme == .apple ? (isDark ? 0.3 : 0.05) : (isDark ? 0.3 : 0.03))

      return Shadow(
        color: .black.opacity(opacity),
        radius: currentTheme == .airbnb ? 8 : 2,
        x: 0,
        y: currentTheme == .airbnb ? 3 : 1
      )
    }
  }

  // MARK: - Layout
  /// 布局系统
  enum Layout {
    /// 表单字段内边距
    static let formFieldPadding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    /// 容器内边距
    static let containerPadding = EdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20)
    /// 状态栏内边距
    static let statusBarPadding = EdgeInsets(top: 12, leading: 20, bottom: 8, trailing: 20)
    /// 大页面容器内边距
    static let largeContainerPadding = EdgeInsets(
      top: 48,
      leading: 32,
      bottom: 24,
      trailing: 32
    )
  }

  /// 切换主题
  /// - Parameter theme: 目标主题类型
  static func switchTheme(to theme: ThemeType) {
    currentTheme = theme
  }
}

// MARK: - Helper Structures
/// 阴影配置结构
struct Shadow {
  /// 阴影颜色
  let color: Color
  /// 阴影半径
  let radius: CGFloat
  /// 水平偏移
  let x: CGFloat
  /// 垂直偏移
  let y: CGFloat
}

// MARK: - Helper Extensions
extension Color {
  /// 创建支持浅色/深色模式的颜色
  /// - Parameters:
  ///   - light: 浅色模式下的十六进制颜色值
  ///   - dark: 深色模式下的十六进制颜色值
  init(light: String, dark: String) {
    self.init(
      nsColor: NSColor(name: nil) { appearance in
        NSColor(hex: appearance.name.rawValue.contains("Dark") ? dark : light)
      }
    )
  }

  /// 通过十六进制字符串创建颜色
  /// - Parameter hex: 十六进制颜色值
  init(hex: String) {
    self.init(nsColor: NSColor(hex: hex))
  }
}

extension NSColor {
  /// 通过十六进制字符串创建NSColor
  /// - Parameter hex: 十六进制颜色值（支持3位、6位、8位）
  convenience init(hex: String) {
    let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)

    let (a, r, g, b): (UInt64, UInt64, UInt64, UInt64) = {
      switch hex.count {
      case 3: return (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
      case 6: return (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
      case 8: return (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
      default: return (1, 1, 1, 0)
      }
    }()

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
  /// 应用卡片样式
  /// 包括背景色、圆角和阴影
  func scheduleCardStyle() -> some View {
    self
      .background(DesignSystem.Colors.background)
      .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
      .modifier(CardShadowModifier())
  }

  /// 应用表单字段样式
  /// 包括高度、内边距、背景色、圆角和边框
  func scheduleFormFieldStyle() -> some View {
    self
      .frame(height: DesignSystem.Dimensions.formFieldHeight)
      .padding(DesignSystem.Layout.formFieldPadding)
      .background(DesignSystem.Colors.background)
      .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
          .stroke(DesignSystem.Colors.borderGray, lineWidth: 1)
      )
  }
}

/// 卡片阴影修饰符
private struct CardShadowModifier: ViewModifier {
  @Environment(\.colorScheme) var colorScheme

  func body(content: Content) -> some View {
    let shadow = DesignSystem.Shadows.cardShadow(colorScheme: colorScheme)
    content.shadow(
      color: shadow.color,
      radius: shadow.radius,
      x: shadow.x,
      y: shadow.y
    )
  }
}

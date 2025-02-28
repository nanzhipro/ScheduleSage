//
//  DesignSystem.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-25.
//

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
                colors: colorScheme == .dark ? [
                    Colors.darkGradientTop,      // 深色模式顶部色
                    Colors.darkGradientMiddle,   // 深色模式中间色
                    Colors.background            // 深色模式底部色
                ] : [
                    Colors.lightGradientTop,     // 浅色模式顶部色
                    Colors.lightGradientMiddle,  // 浅色模式中间色
                    Colors.background            // 浅色模式底部色
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
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
            let opacity = currentTheme == .airbnb ? (isDark ? 0.35 : 0.06) :
                       (currentTheme == .apple ? (isDark ? 0.3 : 0.05) : (isDark ? 0.3 : 0.03))
            
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
        self.init(nsColor: NSColor(name: nil) { appearance in
            NSColor(hex: appearance.name.rawValue.contains("Dark") ? dark : light)
        })
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

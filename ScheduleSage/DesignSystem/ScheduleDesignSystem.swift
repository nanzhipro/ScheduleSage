import SwiftUI

// MARK: - Theme Type
enum ThemeType {
    case apple   // 苹果风格
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
                return Color(hex: "007AFF")  // 苹果蓝
            case .wechat:
                return Color(hex: "07C160")  // 微信绿
            }
        }
        
        static var primaryBackground: Color {
            switch currentTheme {
            case .apple:
                return Color(hex: "F2F2F7")
            case .wechat:
                return Color(hex: "F7F7F7")
            }
        }
        
        // Base Colors
        static let background = Color.white
        
        static var secondaryGray: Color {
            switch currentTheme {
            case .apple:
                return Color(hex: "86868B")
            case .wechat:
                return Color(hex: "9B9B9B")
            }
        }
        
        static var lightGray: Color {
            switch currentTheme {
            case .apple:
                return Color(hex: "F2F2F7")
            case .wechat:
                return Color(hex: "F7F7F7")
            }
        }
        
        static var containerGray: Color {
            switch currentTheme {
            case .apple:
                return Color(hex: "F8F8FA")
            case .wechat:
                return Color(hex: "F8F8F8")
            }
        }
        
        static var borderGray: Color {
            switch currentTheme {
            case .apple:
                return Color(hex: "E5E5E5")
            case .wechat:
                return Color(hex: "EBEDF0")
            }
        }
        
        static var success: Color { primary }
        
        // Text Colors
        static var primaryText: Color {
            switch currentTheme {
            case .apple:
                return .black
            case .wechat:
                return Color(hex: "2C2C2C")
            }
        }
        
        static var secondaryText: Color {
            switch currentTheme {
            case .apple:
                return Color(hex: "86868B")
            case .wechat:
                return Color(hex: "9B9B9B")
            }
        }
        
        static var tertiaryText: Color {
            switch currentTheme {
            case .apple:
                return Color(hex: "C7C7CC")
            case .wechat:
                return Color(hex: "BFBFBF")
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
    }
    
    // MARK: - Dimensions
    enum Dimensions {
        // Container Sizes
        static let containerWidth: CGFloat = 440
        static let containerHeight: CGFloat = 543  // 原高度 418 增加 30%
        static let confirmPageHeight: CGFloat = 550
        
        // Corner Radii
        static let containerCornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 8
        static let buttonCornerRadius: CGFloat = 8
        static let headerCornerRadius: CGFloat = 8
        
        // Component Heights
        static let headerHeight: CGFloat = 44
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
                    color: .black.opacity(0.12),
                    radius: 8,
                    x: 0,
                    y: 2
                )
            case .wechat:
                return Shadow(
                    color: .black.opacity(0.05),
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
                    color: .black.opacity(0.05),
                    radius: 2,
                    x: 0,
                    y: 1
                )
            case .wechat:
                return Shadow(
                    color: .black.opacity(0.03),
                    radius: 2,
                    x: 0,
                    y: 1
                )
            }
        }
    }
    
    // MARK: - Layout
    enum Layout {
        static let formFieldPadding = EdgeInsets(
            top: 16,    // 微信表单内边距
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        
        static let containerPadding = EdgeInsets(
            top: 20,    // 微信容器内边距
            leading: 20,
            bottom: 20,
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
    init(hex: String) {
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
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
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
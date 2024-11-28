import SwiftUI

// MARK: - Design System
enum ScheduleDesignSystem {
    // MARK: - Colors
    enum Colors {
        // Base Colors
        static let background = Color.white
        static let primaryBlue = Color(hex: "007AFF")
        static let secondaryGray = Color(hex: "86868B")
        static let lightGray = Color(hex: "F2F2F7")
        static let containerGray = Color(hex: "F8F8FA")
        static let borderGray = Color(hex: "E5E5E5")
        static let success = Color(hex: "34C759")
        
        // Text Colors
        static let primaryText = Color.black
        static let secondaryText = Color(hex: "86868B")
        
        // Button Colors
        static let cancelButtonBackground = Color(hex: "F5F5F5")
        
        // Icon Colors
        static let iconGray = Color(hex: "666666")
    }
    
    // MARK: - Typography
    enum Typography {
        // Headers
        static let headerTitle = Font.system(size: 17, weight: .medium)
        
        // Content
        static let bodyLarge = Font.system(size: 15)
        static let bodyRegular = Font.system(size: 13)
        static let bodyMedium = Font.system(size: 13, weight: .medium)
        
        // Labels
        static let formLabel = Font.system(size: 13)
        static let buttonLabel = Font.system(size: 14)
        
        // Event Title
        static let eventTitle = Font.system(size: 17, weight: .medium)
        
        // Status
        static let statusText = Font.system(size: 13)
        static let emptyStateTitle = Font.system(size: 15, weight: .medium)
        static let methodLabel = Font.system(size: 13)
    }
    
    // MARK: - Dimensions
    enum Dimensions {
        // Container
        static let containerWidth: CGFloat = 440
        static let containerHeight: CGFloat = 418
        static let confirmPageHeight: CGFloat = 550
        
        // Corners
        static let containerCornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 8
        static let buttonCornerRadius: CGFloat = 8
        static let headerCornerRadius: CGFloat = 8
        
        // Components
        static let headerHeight: CGFloat = 44
        static let formFieldHeight: CGFloat = 44
        static let buttonHeight: CGFloat = 44
        static let importButtonHeight: CGFloat = 44
        
        // Icons
        static let statusIconSize: CGFloat = 24
        static let methodIconSize: CGFloat = 32
        static let addButtonSize: CGFloat = 28
        static let selectionIndicatorSize: CGFloat = 8
        static let crownIconSize: CGFloat = 24
        
        // Empty State
        static let emptyStateIconSize: CGFloat = 80
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let horizontal: CGFloat = 24
        static let vertical: CGFloat = 24
        static let formFieldSpacing: CGFloat = 24
        static let contentPadding: CGFloat = 16
        static let iconSpacing: CGFloat = 8
        static let elementSpacing: CGFloat = 16
        
        // Header
        static let headerHorizontalPadding: CGFloat = 24
    }
    
    // MARK: - Shadows
    enum Shadows {
        static let containerShadow = Shadow(
            color: .black.opacity(0.12),
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let cardShadow = Shadow(
            color: .black.opacity(0.05),
            radius: 2,
            x: 0,
            y: 1
        )
    }
    
    // MARK: - Layout
    enum Layout {
        static let formFieldPadding = EdgeInsets(
            top: 20,
            leading: 16,
            bottom: 20,
            trailing: 16
        )
        
        static let containerPadding = EdgeInsets(
            top: 24,
            leading: 24,
            bottom: 24,
            trailing: 24
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
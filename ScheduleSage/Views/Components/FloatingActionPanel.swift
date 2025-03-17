//
//  FloatingActionPanel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 悬浮操作面板
/// 提供一个悬浮于主界面之上的操作区域，包含多个操作按钮
struct FloatingActionPanel<Content: View>: View {
    let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
                .padding(.horizontal, DesignSystem.Spacing.largeContentSpacing)
                .padding(.vertical, 4) // 增加一点垂直内边距，确保内容不会太紧凑
        }
        .background(
            ZStack {
                // 底层背景 - 提供基础颜色和模糊效果
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        colorScheme == .dark ? 
                            DesignSystem.Colors.cardBackground.opacity(0.75) : 
                            Color.white.opacity(0.5)
                    )
                
                // 毛玻璃效果
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(colorScheme == .dark ? 0.6 : 0.4)
                
                // 边框效果
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        colorScheme == .dark ?
                            DesignSystem.Colors.primary.opacity(0.15) :
                            DesignSystem.Colors.primary.opacity(0.08),
                        lineWidth: 0
                    )
            }
        )
        .shadow(
            color: colorScheme == .dark ?
                DesignSystem.Colors.primary.opacity(isHovered ? 0.15 : 0.1) :
                Color.black.opacity(isHovered ? 0.12 : 0.08),
            radius: isHovered ? 16 : 12,
            x: 0,
            y: isHovered ? 6 : 4
        )
        // 添加第二层阴影，增强深度感
        .shadow(
            color: colorScheme == .dark ?
                Color.black.opacity(0.25) :
                Color.black.opacity(0.05),
            radius: 3,
            x: 0,
            y: 2
        )
    }
}

/// 悬浮操作按钮
/// 提供一个在悬浮面板中使用的操作按钮，包含图标和文本
struct FloatingActionButton: View {
    let iconName: String
    let title: String
    let hintKey: String
    let action: (() -> Void)?
    
    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        iconName: String,
        title: String,
        hintKey: String,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.hintKey = hintKey
        self.action = action
    }
    
    // 根据系统版本和图标名称返回适配的图标名称
    private var adaptedIconName: String {
        // 如果是 macOS 14 及以上版本，且图标是 text.page.fill，则使用 doc.plaintext.fill
        if #available(macOS 14.0, *), iconName == "text.page.fill" {
            return "doc.plaintext.fill"
        }
        return iconName
    }
    
    var body: some View {
        Button(action: handleButtonTap) {
            VStack(spacing: 6) { // 减少垂直间距
                // 图标 - 添加白色圆形背景
                ZStack {
                    // 白色圆形背景
                    Circle()
                        .fill(colorScheme == .dark ? 
                              Color.black.opacity(0.2) : 
                              Color.white.opacity(0.9))
                        .frame(width: 48, height: 48)
                        .shadow(
                            color: colorScheme == .dark ?
                                DesignSystem.Colors.primary.opacity(isHovered ? 0.2 : 0.1) :
                                Color.black.opacity(isHovered ? 0.1 : 0.05),
                            radius: isHovered ? 4 : 2,
                            x: 0,
                            y: isHovered ? 2 : 1
                        )
                    
                    // 图标 - 使用适配的图标名称
                    Image(systemName: adaptedIconName)
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.1 : 1.0))
                }
                
                // 按钮文本
                Text(title)
                    .font(DesignSystem.Typography.caption) // 使用更小的字体
                    .foregroundColor(
                        isHovered ? 
                            DesignSystem.Colors.primary : 
                            DesignSystem.Colors.primaryText
                    )
                    .opacity(isHovered ? 1.0 : 0.9)
                    .fixedSize(horizontal: true, vertical: false) // 确保文本不会换行
                    .lineLimit(1) // 限制为单行
            }
            .padding(.vertical, 4) // 减少垂直内边距
            .padding(.horizontal, 4) // 减少水平内边距
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .help(NSLocalizedString(hintKey, comment: ""))
    }
    
    private func handleButtonTap() {
        withAnimation(.easeOut(duration: 0.1)) {
            isPressed = true
        }
        
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = false
            }
            
            action?()
        }
    }
}

#if DEBUG
struct FloatingActionPanel_Previews: PreviewProvider {
    static var previews: some View {
        FloatingActionPanel {
            HStack(spacing: 32) { // 减少按钮间距
                FloatingActionButton(
                    iconName: "clipboard.fill",
                    title: "从剪贴板导入",
                    hintKey: "hint.clipboard_import"
                )
                
                FloatingActionButton(
                    iconName: "text.page.fill",
                    title: "手动输入",
                    hintKey: "hint.manual_input"
                )
                
                FloatingActionButton(
                    iconName: "photo.fill",
                    title: "图片导入",
                    hintKey: "hint.image_import"
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 
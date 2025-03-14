//
//  CalendarFeedsBackgroundView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 日历事件流背景视图
/// 以若隐若现的方式在背景中展示当日日历事件
struct CalendarFeedsBackgroundView: View {
    // MARK: - 属性
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    
    // 控制整体透明度 - 提高暗黑模式下的可见度
    private var baseOpacity: Double {
        colorScheme == .dark ? 0.9 : 0.75
    }
    
    // MARK: - 视图主体
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // 日历事件流容器 - 放在顶部而不是底部
                VStack {
                    CalendarFeedsView()
                        .frame(width: min(geometry.size.width * 0.8, 500))
                        .padding(.horizontal, DesignSystem.Spacing.horizontal)
                        .padding(.vertical, 16)
                        .background(
                            ZStack {
                                // 毛玻璃效果 - 移除了底层背景色
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .opacity(colorScheme == .dark ? 0.5 : 0.3)
                                
                                // 边框效果 - 增强暗黑模式下的边框可见度
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        colorScheme == .dark ?
                                            DesignSystem.Colors.primary.opacity(0.2) :
                                            DesignSystem.Colors.primary.opacity(0.05),
                                        lineWidth: 0.5
                                    )
                            }
                        )
                        .shadow(
                            color: colorScheme == .dark ?
                                DesignSystem.Colors.primary.opacity(0.2) :
                                Color.black.opacity(0.05),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                        // 添加第二层阴影，增强深度感
                        .shadow(
                            color: colorScheme == .dark ?
                                Color.black.opacity(0.3) :
                                Color.black.opacity(0.03),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                }
                .opacity(baseOpacity)
                .padding(.top, 250) // 增加顶部间距，确保不会与顶部元素重叠
                
                Spacer() // 将内容推到顶部
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false) // 禁止交互，确保不会干扰主要内容
        }
    }
}

// MARK: - 预览
#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        
        CalendarFeedsBackgroundView()
    }
    .frame(width: 600, height: 400)
    .preferredColorScheme(.dark) // 添加暗黑模式预览
} 
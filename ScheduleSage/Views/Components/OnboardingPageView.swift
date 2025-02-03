//
//  OnboardingPageView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import SwiftUI

/// OnboardingPageView
/// Onboarding 单页视图
/// 展示单个引导页的内容
struct OnboardingPageView: View {
    let page: OnboardingPage
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            // 图标
            Image(systemName: page.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundStyle(DesignSystem.Colors.primary)
                .symbolEffect(.bounce, value: page)
            
            VStack(spacing: 16) {
                // 标题
                Text(page.title)
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                // 描述
                Text(page.description)
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 权限请求按钮
            if page.requiresPermission {
                permissionButton
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var permissionButton: some View {
        switch page.permissionType {
        case .calendar:
            if !viewModel.calendarPermissionGranted {
                Button(action: {
                    Task {
                        await viewModel.requestCalendarPermission()
                    }
                }) {
                    Label(
                        NSLocalizedString("onboarding.permission.calendar.button", comment: ""),
                        systemImage: "calendar.badge.plus"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
            }
            
        case .notification:
            if !viewModel.notificationPermissionGranted {
                Button(action: {
                    Task {
                        await viewModel.requestNotificationPermission()
                    }
                }) {
                    Label(
                        NSLocalizedString("onboarding.permission.notification.button", comment: ""),
                        systemImage: "bell.badge"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
            }
            
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "Welcome to ScheduleSage",
            description: "Your smart calendar assistant",
            iconName: "calendar.badge.plus"
        ),
        viewModel: OnboardingViewModel()
    )
} 
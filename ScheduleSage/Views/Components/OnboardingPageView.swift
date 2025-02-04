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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.vertical) {
            pageIcon
            pageContent
            if page.requiresPermission,
               let permissionType = page.permissionType {
                PermissionButton(type: permissionType, viewModel: viewModel)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isAnimating) { _, newValue in
            triggerAnimation()
        }
        .onAppear {
            triggerAnimation()
        }
    }
    
    // MARK: - Subviews
    
    private var pageIcon: some View {
        Image(systemName: page.iconName)
            .font(.system(size: 48, weight: .medium))
            .imageScale(.large)
            .symbolRenderingMode(.hierarchical)
            .frame(width: DesignSystem.Dimensions.emptyStateIconSize, 
                   height: DesignSystem.Dimensions.emptyStateIconSize)
            .foregroundStyle(DesignSystem.Colors.primary)
            .symbolEffect(.bounce, value: isAnimating)
            .transition(.scale.combined(with: .opacity))
            .contentShape(Rectangle())
    }
    
    private var pageContent: some View {
        VStack(spacing: DesignSystem.Spacing.textSpacing) {
            Text(page.title)
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(DesignSystem.Typography.bodyLarge)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, DesignSystem.Spacing.sectionSpacing)
    }
    
    private func triggerAnimation() {
        withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
            isAnimating.toggle()
        }
    }
}

// MARK: - Permission Button

/// 权限请求按钮组件
private struct PermissionButton: View {
    let type: OnboardingPage.PermissionType
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Group {
            if !isPermissionGranted {
                requestButton
            } else {
                grantedLabel
            }
        }
        .padding(.top, DesignSystem.Spacing.elementSpacing)
    }
    
    private var isPermissionGranted: Bool {
        switch type {
        case .calendar:
            return viewModel.calendarPermissionGranted
        case .notification:
            return viewModel.notificationPermissionGranted
        }
    }
    
    private var requestButton: some View {
        Button(action: requestPermission) {
            Label(buttonTitle, systemImage: buttonIcon)
                .font(DesignSystem.Typography.buttonLabel)
                .frame(minWidth: 180)
                .frame(height: DesignSystem.Dimensions.buttonHeight)
        }
        .buttonStyle(.borderedProminent)
        .tint(DesignSystem.Colors.primary)
        .disabled(viewModel.isRequestingPermission)
        .help(helpText)
        .shadow(
            color: DesignSystem.Colors.primary.opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: DesignSystem.Colors.primary.opacity(isHovered ? 0.4 : 0.3),
            radius: isHovered ? 6 : 4,
            x: 0,
            y: isHovered ? 3 : 2
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var grantedLabel: some View {
        Label(grantedTitle, systemImage: "checkmark.circle.fill")
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.success)
    }
    
    private func requestPermission() {
        Task {
            switch type {
            case .calendar:
                await viewModel.requestCalendarPermission()
            case .notification:
                await viewModel.requestNotificationPermission()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    @State private var isHovered = false
    
    private var buttonTitle: LocalizedStringKey {
        switch type {
        case .calendar:
            return "onboarding.permission.calendar.button"
        case .notification:
            return "onboarding.permission.notification.button"
        }
    }
    
    private var grantedTitle: LocalizedStringKey {
        switch type {
        case .calendar:
            return "onboarding.permission.calendar.granted"
        case .notification:
            return "onboarding.permission.notification.granted"
        }
    }
    
    private var buttonIcon: String {
        switch type {
        case .calendar:
            return "calendar.badge.plus"
        case .notification:
            return "bell.badge"
        }
    }
    
    private var helpText: LocalizedStringKey {
        switch type {
        case .calendar:
            return "onboarding.permission.calendar.help"
        case .notification:
            return "onboarding.permission.notification.help"
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
    .frame(width: DesignSystem.Dimensions.mainViewWidth, 
           height: DesignSystem.Dimensions.mainViewHeight)
} 
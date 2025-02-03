//
//  OnboardingPage.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import SwiftUI

/// OnboardingPage
/// Onboarding 页面数据模型
/// 定义单个引导页的内容和行为
public struct OnboardingPage: Identifiable, Equatable {
    public let id = UUID()
    
    /// 页面标题
    public let title: LocalizedStringKey
    
    /// 页面详细说明
    public let description: LocalizedStringKey
    
    /// 页面图标名称（SF Symbols）
    public let iconName: String
    
    /// 是否需要权限
    public let requiresPermission: Bool
    
    /// 权限类型
    public let permissionType: PermissionType?
    
    /// 是否是最后一页
    public let isLastPage: Bool
    
    // MARK: - Permission Types
    
    public enum PermissionType {
        case calendar
        case notification
        
        var title: LocalizedStringKey {
            switch self {
            case .calendar:
                return "onboarding.permission.calendar.title"
            case .notification:
                return "onboarding.permission.notification.title"
            }
        }
        
        var description: LocalizedStringKey {
            switch self {
            case .calendar:
                return "onboarding.permission.calendar.description"
            case .notification:
                return "onboarding.permission.notification.description"
            }
        }
        
        var iconName: String {
            switch self {
            case .calendar:
                return "calendar"
            case .notification:
                return "bell"
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(
        title: LocalizedStringKey,
        description: LocalizedStringKey,
        iconName: String,
        requiresPermission: Bool = false,
        permissionType: PermissionType? = nil,
        isLastPage: Bool = false
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.requiresPermission = requiresPermission
        self.permissionType = permissionType
        self.isLastPage = isLastPage
    }
}

// MARK: - Default Pages

public extension OnboardingPage {
    /// 默认的引导页面配置
    static var defaultPages: [OnboardingPage] {
        [
            OnboardingPage(
                title: "onboarding.welcome.title",
                description: "onboarding.welcome.description",
                iconName: "calendar.badge.plus"
            ),
            OnboardingPage(
                title: "onboarding.features.title",
                description: "onboarding.features.description",
                iconName: "sparkles"
            ),
            OnboardingPage(
                title: "onboarding.calendar.title",
                description: "onboarding.calendar.description",
                iconName: "calendar",
                requiresPermission: true,
                permissionType: .calendar
            ),
            OnboardingPage(
                title: "onboarding.notification.title",
                description: "onboarding.notification.description",
                iconName: "bell",
                requiresPermission: true,
                permissionType: .notification,
                isLastPage: true
            )
        ]
    }
}
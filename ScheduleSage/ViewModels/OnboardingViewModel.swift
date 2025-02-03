//
//  OnboardingViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import SwiftUI
import Combine
import OSLog

/// OnboardingViewModel
/// Onboarding 页面的视图模型
/// 负责管理引导页面的状态和行为
@MainActor
public final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 当前页面索引
    @Published var currentPageIndex: Int = 0
    
    /// 是否显示引导页
    @Published var isPresented: Bool = false
    
    /// 页面数组
    @Published private(set) var pages: [OnboardingPage]
    
    /// 日历权限状态
    @Published private(set) var calendarPermissionGranted: Bool = false
    
    /// 通知权限状态
    @Published private(set) var notificationPermissionGranted: Bool = false
    
    // MARK: - Private Properties
    
    private let calendarManager = CalendarManager()
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.schedulesage", category: "OnboardingViewModel")
    
    // MARK: - Computed Properties
    
    /// 当前页面
    var currentPage: OnboardingPage {
        pages[currentPageIndex]
    }
    
    /// 是否可以前进
    var canGoForward: Bool {
        currentPageIndex < pages.count - 1
    }
    
    /// 是否可以后退
    var canGoBack: Bool {
        currentPageIndex > 0
    }
    
    /// 是否是最后一页
    var isLastPage: Bool {
        currentPage.isLastPage
    }
    
    // MARK: - Initialization
    
    public init(pages: [OnboardingPage] = OnboardingPage.defaultPages) {
        self.pages = pages
        setupSubscriptions()
        checkInitialState()
    }
    
    // MARK: - Public Methods
    
    /// 前进到下一页
    public func goToNextPage() {
        guard canGoForward else { return }
        withAnimation(.spring()) {
            currentPageIndex += 1
        }
    }
    
    /// 返回上一页
    public func goToPreviousPage() {
        guard canGoBack else { return }
        withAnimation(.spring()) {
            currentPageIndex -= 1
        }
    }
    
    /// 完成引导
    public func finish() {
        withAnimation {
            isPresented = false
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    /// 请求日历权限
    public func requestCalendarPermission() async {
        do {
            calendarPermissionGranted = try await calendarManager.requestAccess()
        } catch {
            logger.error("Calendar permission request failed: \(error.localizedDescription)")
        }
    }
    
    /// 请求通知权限
    public func requestNotificationPermission() async {
        notificationPermissionGranted = await notificationManager.requestAuthorization()
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // 监听权限状态变化
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.checkPermissions()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkInitialState() {
        // 检查是否需要显示引导页
        isPresented = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // 检查初始权限状态
        Task {
            await checkPermissions()
        }
    }
    
    private func checkPermissions() async {
        // 检查日历权限
        do {
            calendarPermissionGranted = try await calendarManager.requestAccess()
        } catch {
            logger.error("Calendar permission check failed: \(error.localizedDescription)")
        }
        
        // 检查通知权限
        notificationPermissionGranted = await notificationManager.checkNotificationStatus()
    }
}

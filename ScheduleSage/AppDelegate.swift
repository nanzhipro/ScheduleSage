//
//  AppDelegate.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import AppKit
import SwiftUI
import OSLog
import Sentry

/// 应用程序委托
/// 负责管理应用程序的生命周期和主要功能
/// - Note: 使用 @MainActor 确保在主线程上执行UI操作
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    
    /// 状态栏项
    private var statusItem: NSStatusItem?
    
    /// 弹出窗口
    private var popover: NSPopover?
    
    /// 主视图模型
    private var viewModel: AddScheduleViewModel?
    
    /// 主窗口控制器
    private var windowController: MainWindowController?
    
    /// 全局事件监视器
    private var eventMonitor: Any?
    
    /// 键盘事件监视器
    private var keyboardMonitor: Any?
    
    /// 应用日志记录器
    private let logger = Logger(
        subsystem: "com.tiwenlab.schedulesage",
        category: "AppDelegate"
    )
    
    /// 日历管理器
    private let calendarManager = CalendarManager()
    
    /// 剪贴板管理器
    private let clipboardManager = ClipboardManager()
    
    /// 通知管理器
    private let notificationManager = NotificationManager.shared
    
    /// 令牌提供者
    private let tokenProvider: SimpleJWTTokenProvider
    
    /// 弹出窗口显示状态
    private var isPopoverShown = false
    
    /// 窗口模式设置
    @AppStorage("useWindowMode") private var useWindowMode = true
    
    /// 引导页完成状态
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    /// 应用包标识符
    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.tiwenlab.schedulesage"
    
    /// 引导页窗口控制器
    private var onboardingWindowController: NSWindowController?
    
    // MARK: - Lifecycle
    
    override init() {
        self.tokenProvider = APIConfig.shared.getTokenProvider()
        super.init()
    }
    
    /// 应用程序启动完成
    /// - Parameter notification: 通知对象
    func applicationDidFinishLaunching(_ notification: Notification) {
        initializeTheme()
        
        guard checkAndActivateExistingInstance() else { return }
        
        Task {
            await setupApplication()
        }
    }
    
    deinit {
        [eventMonitor, keyboardMonitor].forEach { monitor in
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
    
    // MARK: - Setup Methods
    
    /// 设置应用程序
    /// - Complexity: O(1)
    private func setupApplication() async {
        logger.info("AppDelegate did finish launching")
        
        if !hasCompletedOnboarding {
            showOnboarding()
        }
        
        viewModel = AddScheduleViewModel()
        configureStatusItem()
        configurePopover()
        configureEventMonitor()
        configureKeyboardMonitor()
        configureSentry()
    }
    
    /// 配置 Sentry 错误跟踪
    private func configureSentry() {
        SentrySDK.start { options in
            options.dsn = "https://8dbe56154a591426c2ecb7ed66018a1a@o4508634309066752.ingest.us.sentry.io/4508822914793472"
            options.debug = false
            options.tracesSampleRate = 1.0
        }
    }
    
    /// 配置状态栏图标
    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            let configuration = NSImage.SymbolConfiguration(
                pointSize: 14,
                weight: .medium
            )
            button.image = NSImage(
                systemSymbolName: "calendar.badge.plus",
                accessibilityDescription: "ScheduleSage"
            )?.withSymbolConfiguration(configuration)
            
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func configurePopover() {
        guard let viewModel else { return }
        
        let contentView = AddScheduleView()
            .environmentObject(viewModel)
        
        if useWindowMode {
            windowController = MainWindowController(
                contentView: contentView,
                viewModel: viewModel,
                size: NSSize(width: 400, height: 600)
            )
            viewModel.windowController = windowController
        } else {
            let popover = NSPopover()
            popover.contentSize = NSSize(width: 400, height: 600)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: contentView)
            popover.delegate = self
            self.popover = popover
        }
    }
    
    private func configureEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self,
                  self.isPopoverShown,
                  let window = NSApp.windows.first(where: { $0.isKeyWindow }),
                  !NSPointInRect(event.locationInWindow, window.frame) else { return }
            
            self.dismissPopover()
        }
    }
    
    private func configureKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            
            // 处理 Command + V 的剪贴板监听
            if event.modifierFlags.contains(.command),
               event.keyCode == 9,  // V key
               NSApp.isActive,
               self.viewModel?.isKeyboardMonitorEnabled == true,
               let content = self.clipboardManager.checkClipboard() {
                self.viewModel?.handleClipboardContent(content)
                return nil
            }
            
            // 处理 Shift + Command + C 的截图功能
            if event.modifierFlags.contains([.command, .shift]),
               event.keyCode == 8 {  // C key
                self.handleScreenshot()
                return nil
            }
            
            return event
        }
    }
    
    private func handleScreenshot() {
        let results = ScreenshotManager.shared.captureAllWindows()
        
        let successCount = results.filter { 
            if case .success = $0 { return true }
            return false 
        }.count
        
        if successCount > 0 {
            notificationManager.sendNotification(
                title: NSLocalizedString("screenshot.success.title", comment: "Screenshot success title"),
                body: NSLocalizedString("screenshot.success.message", comment: "Screenshot success message")
            )
        } else {
            notificationManager.sendNotification(
                title: NSLocalizedString("screenshot.failure.title", comment: "Screenshot failure title"),
                body: NSLocalizedString("screenshot.failure.message", comment: "Screenshot failure message")
            )
        }
    }
    
    // MARK: - Instance Management
    private func checkAndActivateExistingInstance() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        guard let existingInstance = runningApps.first(where: {
            $0.bundleIdentifier == Self.bundleIdentifier && $0 != NSRunningApplication.current
        }) else { return true }
        
        if #available(macOS 14.0, *) {
            existingInstance.activate()
        } else {
            existingInstance.activate(options: [.activateIgnoringOtherApps])
        }
        
        if let url = URL(string: "schedulesage://show") {
            NSWorkspace.shared.open(url)
        }
        
        NSApp.terminate(nil)
        return false
    }
    
    // MARK: - Window Management
    @objc private func togglePopover() {
        useWindowMode ? toggleWindow() : toggleAddScheduleView()
    }
    
    private func toggleWindow() {
        guard let window = windowController?.window else { return }
        
        if window.isVisible && window.isKeyWindow {
            (window as? CustomMainWindow)?.closeWindow()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            windowController?.showWindow(from: statusItem)
        }
    }
    
    private func toggleAddScheduleView() {
        guard let button = statusItem?.button else { return }
        
        NSApp.activate(ignoringOtherApps: true)
        
        if isPopoverShown {
            dismissPopover()
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.windows.first(where: { $0.isKeyWindow })?.makeKeyAndOrderFront(nil)
        }
    }
    
    private func dismissPopover() {
        Task { @MainActor in
            viewModel?.handlePopoverDisappear()
            popover?.performClose(nil)
            isPopoverShown = false
        }
    }
    
    private func showOnboarding() {
        let onboardingView = OnboardingView()
            .environment(\.onboardingCompletion, { [weak self] in
                self?.hasCompletedOnboarding = true
                self?.onboardingWindowController?.close()
                self?.onboardingWindowController = nil
                
                // 延迟一帧显示主窗口，确保引导页面完全关闭
                DispatchQueue.main.async {
                    if self?.useWindowMode == true {
                        self?.windowController?.showWindow(from: self?.statusItem)
                    } else {
                        self?.toggleAddScheduleView()
                    }
                }
            })
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: DesignSystem.Dimensions.mainViewWidth, height: DesignSystem.Dimensions.mainViewHeight),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        window.center()
        window.contentView = NSHostingView(rootView: onboardingView)
        window.title = NSLocalizedString("onboarding.window.title", comment: "")
        window.isReleasedWhenClosed = false
        
        onboardingWindowController = NSWindowController(window: window)
        onboardingWindowController?.showWindow(nil)
        
        if let onboardingWindow = onboardingWindowController?.window {
            NSApp.activate(ignoringOtherApps: true)
            onboardingWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    // MARK: - Theme Initialization
    private func initializeTheme() {
        let defaults = UserDefaults.standard
        let themeKey = "currentTheme"
        
        // 如果存在主题设置，使用已保存的主题
        if let savedTheme = defaults.string(forKey: themeKey),
           let theme = ThemeType(rawValue: savedTheme) {
            DesignSystem.switchTheme(to: theme)
        } else {
            // 如果不存在主题设置，使用默认的 WeChat 主题
            let defaultTheme = ThemeType.wechat
            defaults.set(defaultTheme.rawValue, forKey: themeKey)
            DesignSystem.switchTheme(to: defaultTheme)
        }
    }
}

// MARK: - NSPopoverDelegate
extension AppDelegate: NSPopoverDelegate {
    /// 弹出窗口即将显示
    func popoverWillShow(_ notification: Notification) {
        isPopoverShown = true
    }
    
    /// 弹出窗口即将关闭
    func popoverWillClose(_ notification: Notification) {
        isPopoverShown = false
        viewModel?.handlePopoverDisappear()
    }
}

// MARK: - URL Handling
extension AppDelegate {
    /// 处理应用程序 URL 打开请求
    /// - Parameters:
    ///   - application: 应用程序实例
    ///   - urls: 要打开的 URL 数组
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first,
              url.scheme == "schedulesage",
              url.host == "show",
              let button = statusItem?.button,
              !isPopoverShown else { return }
        
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

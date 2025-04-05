import AppKit
import Sentry
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  // MARK: - Properties
  private var keyboardMonitor: Any?
  private var onboardingWindowController: NSWindowController?

  private let logger = LoggerService.makeCompatible(category: "AppDelegate")
  private let calendarManager = CalendarManager()
  private let clipboardManager = ClipboardManager()
  private let notificationManager = NotificationManager.shared
  private let tokenProvider = APIConfig.shared.getTokenProvider()
  @ObservedObject private var iapService = IAPService.shared
  private let authService = AuthenticationService.shared

  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
  private static let bundleIdentifier = AppInfo.bundleIdentifier

  // MARK: - Lifecycle
  func applicationDidFinishLaunching(_ notification: Notification) {
    // 打印应用启动信息
    logAppLaunchInfo()

    logger.info("[App] Application did finish launching")

    // 配置窗口行为
    configureWindowBehavior()

    // 初始化服务
    Task {
      await initializeServices()
    }
  }

  deinit {
    if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor) }
  }

  // 防止关闭最后一个窗口时应用退出
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // 返回 false 表示即使关闭所有窗口，应用也不会退出
    return false
  }

  // MARK: - Setup Methods
  private func initializeServices() async {
    logger.debug("[App] Starting services initialization")

    // 初始化 IAP 服务
    logger.info("[App] Initializing IAP service")
    await IAPService.bootstrap()
    logger.info("[App] IAP service initialization completed")

    logger.notice("[App] Services initialization completed")
  }

  private func configureWindowBehavior() {
    // 配置为单一标签栏应用
    NSWindow.allowsAutomaticWindowTabbing = false

    initializeTheme()
    guard checkAndActivateExistingInstance() else { return }
    Task { await setupApplication() }
  }

  private func setupApplication() async {
    logger.info("[App] Setting up application")

    if !hasCompletedOnboarding {
      showOnboarding()
    }

    configureKeyboardMonitor()
    configureSentry()
    setupChromeExtensionNotification()
  }

  private func configureSentry() {
    SentrySDK.start { options in
      options.dsn = AppConstants.URLs.sentryUrl
      options.debug = false
      options.tracesSampleRate = 1.0
    }
  }

  private func configureKeyboardMonitor() {
    keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self else { return event }

      // 如果当前第一响应者是文本编辑器，不拦截 Command+V
      if let firstResponder = NSApp.keyWindow?.firstResponder,
        firstResponder.isKind(of: NSTextView.self)
      {
        return event
      }

      if event.modifierFlags.contains(.command),
        event.keyCode == 9,
        NSApp.isActive
      {
        NotificationCenter.default.post(name: .commandVPressed, object: nil)
        return nil
      }

      if event.modifierFlags.contains([.command, .shift]),
        event.keyCode == 8
      {
        self.handleScreenshot()
        return nil
      }

      return event
    }
  }

  private func handleScreenshot() {
    let results = ScreenshotManager.shared.captureAllWindows()
    let successCount = results.filter {
      if case .success = $0 { return true }; return false
    }.count

    notificationManager.sendNotification(
      title: NSLocalizedString(successCount > 0 ? "screenshot.success.title" : "screenshot.failure.title", comment: ""),
      body: NSLocalizedString(
        successCount > 0 ? "screenshot.success.message" : "screenshot.failure.message",
        comment: ""
      )
    )
  }

  private func checkAndActivateExistingInstance() -> Bool {
    let runningApps = NSWorkspace.shared.runningApplications
    guard
      let existingInstance = runningApps.first(where: {
        $0.bundleIdentifier == Self.bundleIdentifier && $0 != NSRunningApplication.current
      })
    else { return true }

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

  // 修改为 public 以便从 App 主文件调用
  func showMainWindow() {
    if let mainWindow = NSApp.windows.first(where: { $0.isVisible }) {
      NSApp.activate(ignoringOtherApps: true)
      mainWindow.makeKeyAndOrderFront(nil)
      mainWindow.orderFrontRegardless()
    } else {
      // 如果没有可见窗口，创建新的主窗口
      let newWindow = NSWindow(
        contentRect: NSRect(
          x: 0,
          y: 0,
          width: DesignSystem.Dimensions.mainViewWidth,
          height: DesignSystem.Dimensions.mainViewHeight
        ),
        styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
        backing: .buffered,
        defer: false
      )

      newWindow.titlebarAppearsTransparent = true
      newWindow.titleVisibility = .hidden
      newWindow.backgroundColor = .clear
      newWindow.isOpaque = false  // 确保窗口不是不透明的
      newWindow.hasShadow = true  // 添加窗口阴影
      newWindow.center()

      // 应用毛玻璃效果 - 使用NSVisualEffectView
      if let contentView = newWindow.contentView {
        // 移除已有的毛玻璃视图（如果存在）
        contentView.subviews.forEach { subview in
          if subview is NSVisualEffectView {
            subview.removeFromSuperview()
          }
        }

        // 创建新的毛玻璃效果视图
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .fullScreenUI  // 适合全窗口的毛玻璃效果
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.frame = contentView.bounds
        visualEffectView.autoresizingMask = [.width, .height]

        // 插入毛玻璃效果视图到最底层，确保内容视图在其上方
        contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
      }

      // 创建包含层级视图的结构
      let backgroundView = ZStack {
        // 1. 最底层：毛玻璃背景
        WindowBlurBackground()

        // 2. 中间层：Messenger风格的背景渐变
        WindowBackgroundView()
          .opacity(0.7)  // 降低不透明度以更好地显示底层毛玻璃效果

        // 3. 顶层：主内容视图 - 确保在毛玻璃效果之上
        AddScheduleView()
          .environmentObject(AddScheduleViewModel())
          .environmentObject(AuthenticationViewModel.shared)
          .frame(
            width: DesignSystem.Dimensions.mainViewWidth,
            height: DesignSystem.Dimensions.mainViewHeight
          )
          .zIndex(10)  // 确保内容视图始终在最上层
      }

      newWindow.contentView = NSHostingView(rootView: backgroundView)
      newWindow.title = NSLocalizedString("schedule_add_title", comment: "")
      newWindow.isReleasedWhenClosed = false

      let windowController = NSWindowController(window: newWindow)
      windowController.showWindow(nil)

      NSApp.activate(ignoringOtherApps: true)
      newWindow.makeKeyAndOrderFront(nil)
    }
  }

  private func showOnboarding() {
    let onboardingView = OnboardingView()
      .environment(
        \.onboardingCompletion,
        { [weak self] in
          self?.hasCompletedOnboarding = true
          self?.onboardingWindowController?.close()
          self?.onboardingWindowController = nil

          // 完成引导后显示主窗口
          self?.showMainWindow()
        }
      )

    let window = NSWindow(
      contentRect: NSRect(
        x: 0,
        y: 0,
        width: DesignSystem.Dimensions.mainViewWidth,
        height: DesignSystem.Dimensions.mainViewHeight
      ),
      styleMask: [.titled, .closable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )

    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.backgroundColor = .clear
    window.isOpaque = false  // 确保窗口不是不透明的
    window.hasShadow = true  // 添加窗口阴影
    window.center()

    // 应用毛玻璃效果 - 使用NSVisualEffectView
    if let contentView = window.contentView {
      // 移除已有的毛玻璃视图（如果存在）
      contentView.subviews.forEach { subview in
        if subview is NSVisualEffectView {
          subview.removeFromSuperview()
        }
      }

      // 创建新的毛玻璃效果视图
      let visualEffectView = NSVisualEffectView()
      visualEffectView.material = .fullScreenUI  // 适合全窗口的毛玻璃效果
      visualEffectView.blendingMode = .behindWindow
      visualEffectView.state = .active
      visualEffectView.frame = contentView.bounds
      visualEffectView.autoresizingMask = [.width, .height]

      // 插入毛玻璃效果视图到最底层，确保内容视图在其上方
      contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
    }

    // 创建包含层级视图的结构
    let backgroundView = ZStack {
      // 1. 最底层：毛玻璃背景
      WindowBlurBackground()

      // 2. 中间层：Messenger风格的背景渐变
      WindowBackgroundView()
        .opacity(0.7)  // 降低不透明度以更好地显示底层毛玻璃效果

      // 3. 顶层：引导页内容 - 确保在毛玻璃效果之上
      onboardingView
        .zIndex(10)  // 确保内容视图始终在最上层
    }

    window.contentView = NSHostingView(rootView: backgroundView)
    window.title = NSLocalizedString("onboarding.window.title", comment: "")
    window.isReleasedWhenClosed = false

    onboardingWindowController = NSWindowController(window: window)
    onboardingWindowController?.showWindow(nil)

    if let onboardingWindow = onboardingWindowController?.window {
      NSApp.activate(ignoringOtherApps: true)
      onboardingWindow.makeKeyAndOrderFront(nil)
    }
  }

  private func initializeTheme() {
    let defaults = UserDefaults.standard
    let themeKey = "currentTheme"

    if let savedTheme = defaults.string(forKey: themeKey),
      let theme = ThemeType(rawValue: savedTheme)
    {
      DesignSystem.switchTheme(to: theme)
    } else {
      let defaultTheme = ThemeType.wechat
      defaults.set(defaultTheme.rawValue, forKey: themeKey)
      DesignSystem.switchTheme(to: defaultTheme)
    }
  }

  private func setupChromeExtensionNotification() {
    DistributedNotificationCenter.default().addObserver(
      self,
      selector: #selector(handleChromeExtensionURL(_:)),
      name: Notification.Name("com.schedulesage.chromex.url"),
      object: nil
    )
  }

  @objc private func handleChromeExtensionURL(_ notification: Notification) {
    guard let urlString = notification.userInfo?["url"] as? String,
      let url = URL(string: urlString)
    else {
      logger.error("[App] Invalid URL received from Chrome extension")
      return
    }

    logger.info("[App] Received URL from Chrome extension: \(url.absoluteString)")

    // 显示主窗口
    showMainWindow()

    // 通知 ViewModel 处理 URL
    NotificationCenter.default.post(
      name: Notification.Name("handleChromeExtensionURL"),
      object: nil,
      userInfo: ["url": url]
    )
  }

  // MARK: - Logging
  private func logAppLaunchInfo() {
    let logMessage = """
      [App Launch Info] ==========================================
      \(AppInfo.appInformation)

      \(AppInfo.systemInformation)

      \(AppInfo.environmentInformation)
      =====================================================
      """
    logger.info("\(logMessage)")
  }
}

extension AppDelegate {
  func application(_ application: NSApplication, open urls: [URL]) {
    logger.info("[App] Application open urls: \(urls)")
    guard let url = urls.first,
      url.scheme == "schedulesage"
    else { return }

    switch url.host {
    case "show":
      // 如果已经有窗口，则激活它
      if let existingWindow = NSApp.windows.first(where: { $0.isVisible }) {
        NSApp.activate(ignoringOtherApps: true)
        existingWindow.makeKeyAndOrderFront(nil)
        existingWindow.orderFrontRegardless()
      } else {
        // 如果没有可见窗口，显示主窗口
        showMainWindow()
      }
    default:
      break
    }
  }
}

import AppKit
import SwiftUI
import OSLog
import Sentry

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    private var keyboardMonitor: Any?
    private var onboardingWindowController: NSWindowController?
    private var mainWindowController: MainWindowController?
    
    private let logger = Logger(subsystem: "com.tiwenlab.schedulesage", category: "AppDelegate")
    private let calendarManager = CalendarManager()
    private let clipboardManager = ClipboardManager()
    private let notificationManager = NotificationManager.shared
    private let tokenProvider = APIConfig.shared.getTokenProvider()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.tiwenlab.schedulesage"
    
    // MARK: - Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        initializeTheme()
        guard checkAndActivateExistingInstance() else { return }
        Task { await setupApplication() }
    }
    
    deinit {
        if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor) }
    }
    
    // MARK: - Setup Methods
    private func setupApplication() async {
        logger.info("AppDelegate did finish launching")
        
        if !hasCompletedOnboarding {
            showOnboarding()
        } else {
            showMainWindow()
        }
        
        configureKeyboardMonitor()
        configureSentry()
        
        // 初始化窗口层级
        if let window = NSApp.mainWindow {
            window.level = .normal
        }
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
            
            if event.modifierFlags.contains(.command),
               event.keyCode == 9,
               NSApp.isActive {
                return event
            }
            
            if event.modifierFlags.contains([.command, .shift]),
               event.keyCode == 8 {
                self.handleScreenshot()
                return nil
            }
            
            return event
        }
    }
    
    private func handleScreenshot() {
        let results = ScreenshotManager.shared.captureAllWindows()
        let successCount = results.filter { if case .success = $0 { return true }; return false }.count
        
        notificationManager.sendNotification(
            title: NSLocalizedString(successCount > 0 ? "screenshot.success.title" : "screenshot.failure.title", comment: ""),
            body: NSLocalizedString(successCount > 0 ? "screenshot.success.message" : "screenshot.failure.message", comment: "")
        )
    }
    
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

    private func showOnboarding() {
        let onboardingView = OnboardingView()
            .environment(\.onboardingCompletion, { [weak self] in
                self?.hasCompletedOnboarding = true
                self?.onboardingWindowController?.close()
                self?.onboardingWindowController = nil
                
                // 完成引导后显示主窗口
                self?.showMainWindow()
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
    
    private func showMainWindow() {
        guard let mainWindow = NSApp.windows.first else { return }
                
        // 显示主窗口
        NSApp.activate(ignoringOtherApps: true)
        mainWindow.makeKeyAndOrderFront(nil)
    }
    
    private func initializeTheme() {
        let defaults = UserDefaults.standard
        let themeKey = "currentTheme"
        
        if let savedTheme = defaults.string(forKey: themeKey),
           let theme = ThemeType(rawValue: savedTheme) {
            DesignSystem.switchTheme(to: theme)
        } else {
            let defaultTheme = ThemeType.wechat
            defaults.set(defaultTheme.rawValue, forKey: themeKey)
            DesignSystem.switchTheme(to: defaultTheme)
        }
    }
}

extension AppDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first,
              url.scheme == "schedulesage",
              url.host == "show" else { return }
    }
}

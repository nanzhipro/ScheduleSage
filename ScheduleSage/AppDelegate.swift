import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  private var statusItem: NSStatusItem?
  private var popover: NSPopover?
  private var viewModel: PopoverViewModel?
  private var eventMonitor: Any?
  private let logger = LoggerService()
  private let calendarManager = CalendarManager()
  private var isPopoverShown = false  // 添加状态跟踪
  
  // 新增窗口控制器
  private var windowController: MainWindowController?
  
  // 单实例标识符
  private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.schedulesage.app"
  
  // 使用 AppStorage 来获取窗口模式设置
  @AppStorage("useWindowMode") private var useWindowMode = true
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    // 检查是否已有实例运行
    if !checkAndActivateExistingInstance() {
      return
    }
    
    ScheduleDesignSystem.switchTheme(to: .wechat)
    logger.logInfo("AppDelegate did finish launching")
    
    Task {
      self.viewModel = PopoverViewModel()
      
      setupStatusItem()
      setupPopover()
      setupEventMonitor()
      
      // 请求日历权限
      requestCalendarAccess()
    }
  }
  
  // 检查并激活已存在的实例
  private func checkAndActivateExistingInstance() -> Bool {
    let runningApps = NSWorkspace.shared.runningApplications
    let isAnotherInstanceRunning = runningApps.contains {
      $0.bundleIdentifier == Self.bundleIdentifier && $0 != NSRunningApplication.current
    }
    
    if isAnotherInstanceRunning {
      // 找到其他正在运行的实例
      if let existingInstance = runningApps.first(where: { 
        $0.bundleIdentifier == Self.bundleIdentifier && $0 != NSRunningApplication.current 
      }) {
        // 激活已存在的实例
        existingInstance.activate(options: [.activateIgnoringOtherApps])
        
        // 通过 URL Scheme 触发已存在实例的显示
        if let url = URL(string: "schedulesage://show") {
          NSWorkspace.shared.open(url)
        }
        
        // 退出当前实例
        NSApp.terminate(nil)
        return false
      }
    }
    
    return true
  }
  
  // 处理 URL Scheme 调用
  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first,
          url.scheme == "schedulesage",
          url.host == "show" else {
      return
    }
    
    // 显示 popover
    if let button = statusItem?.button {
      if !isPopoverShown {
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      }
    }
  }

  private func setupStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    if let button = statusItem?.button {
      button.image = NSImage(systemSymbolName: "calendar.badge.plus", accessibilityDescription: "ScheduleSage")
      button.action = #selector(togglePopover)
      button.target = self
    }
  }

  private func setupPopover() {
    guard let viewModel = viewModel else { return }
    
    let contentView = PopoverView()
        .environmentObject(viewModel)
    
    if useWindowMode {
      // 创建窗口控制器
      windowController = MainWindowController(
        contentView: contentView,
        viewModel: viewModel,
        size: NSSize(width: 400, height: 600)
      )
      
      // 设置 viewModel 的 windowController 引用
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

  private func setupEventMonitor() {
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      guard let self = self else { return }
      
      if self.isPopoverShown,  // 使用状态变量
         let window = NSApp.windows.first(where: { $0.isKeyWindow }),
         !NSPointInRect(event.locationInWindow, window.frame)
      {
        self.dismissPopover()
      }
    }
  }

  @objc func togglePopover() {
    if useWindowMode {
      toggleWindow()
    } else {
      togglePopoverView()
    }
  }
  
  private func toggleWindow() {
    if let window = windowController?.window {
      if window.isVisible {
        window.close()
      } else {
        windowController?.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        
        // 确保窗口在屏幕中心显示
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            let newOrigin = NSPoint(
                x: screenRect.midX - windowRect.width / 2,
                y: screenRect.midY - windowRect.height / 2
            )
            window.setFrameOrigin(newOrigin)
        }
      }
    }
  }
  
  private func togglePopoverView() {
    if let button = statusItem?.button {
      if isPopoverShown {
        dismissPopover()
      } else {
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
          window.level = .normal
        }
      }
    }
  }

  private func dismissPopover() {
    // 确保在主线程执行
    Task { @MainActor in
      // 先重置 ViewModel 状态
      viewModel?.handlePopoverDisappear()
      
      // 关闭 popover
      popover?.performClose(nil)
      
      // 更新状态
      isPopoverShown = false
    }
  }

  // MARK: - NSPopoverDelegate
  func popoverWillShow(_ notification: Notification) {
    isPopoverShown = true
  }
  
  func popoverWillClose(_ notification: Notification) {
    isPopoverShown = false
    viewModel?.handlePopoverDisappear()
  }

  // TODO: 增加一个启动引导页面
  private func requestCalendarAccess() {
    // 创建异步任务
    Task { @MainActor in
        do {
            let granted = try await calendarManager.requestAccess()
            
            if granted {
                self.logger.logInfo("Calendar access granted")
                // Update UI state if needed
            } else {
                self.logger.logWarn("Calendar access denied")
                // Show alert or update UI state
            }
        } catch {
            self.logger.logError("Calendar access error: \(error.localizedDescription)")
        }
    }
  }

  deinit {
    if let monitor = eventMonitor {
      NSEvent.removeMonitor(monitor)
    }
  }
}

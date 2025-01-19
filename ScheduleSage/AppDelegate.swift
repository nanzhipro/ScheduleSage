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

  func applicationDidFinishLaunching(_ notification: Notification) {
      ScheduleDesignSystem.switchTheme(to: .apple)
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
    
    let popover = NSPopover()
    popover.contentSize = NSSize(width: 400, height: 600)
    popover.behavior = .transient
    popover.contentViewController = NSHostingController(rootView: contentView)
    popover.delegate = self  // 设置 delegate
    self.popover = popover
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
    if let button = statusItem?.button {
      if isPopoverShown {  // 使用状态变量
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

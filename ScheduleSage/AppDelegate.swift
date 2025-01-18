import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var popover: NSPopover?
  private var viewModel: PopoverViewModel?
  private var eventMonitor: Any?
  private let logger = LoggerService()
  private let calendarManager = CalendarManager()

  func applicationDidFinishLaunching(_ notification: Notification) {
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
    self.popover = popover
  }

  private func setupEventMonitor() {
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      if let window = NSApp.windows.first(where: { $0.isKeyWindow }),
        !NSPointInRect(event.locationInWindow, window.frame)
      {
        self?.dismissPopover()
      }
    }
  }

  @objc func togglePopover() {
    if let button = statusItem?.button {
      if popover?.isShown ?? false {
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
    popover?.performClose(nil)
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

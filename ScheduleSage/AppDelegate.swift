//
//  AppDelegate.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import AppKit
import SwiftUI
import OSLog

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var viewModel: AddScheduleViewModel?
    private var windowController: MainWindowController?
    
    private var eventMonitor: Any?
    private var keyboardMonitor: Any?
    
    private let logger = Logger(subsystem: "com.tiwenlab.schedulesage", category: "AppDelegate")
    private let calendarManager = CalendarManager()
    private let clipboardManager = ClipboardManager()
    private let notificationManager = NotificationManager.shared
    
    private var isPopoverShown = false
    
    @AppStorage("useWindowMode") private var useWindowMode = true
    
    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.tiwenlab.schedulesage"
    
    // MARK: - Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard checkAndActivateExistingInstance() else { return }
        
        Task {
            await setupApplication()
            await requestPermissions()
        }
    }
    
    deinit {
        [eventMonitor, keyboardMonitor].forEach { monitor in
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
    
    // MARK: - Setup
    private func setupApplication() async {
        DesignSystem.switchTheme(to: .wechat)
        logger.info("AppDelegate did finish launching")
        
        viewModel = AddScheduleViewModel()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupKeyboardMonitor()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            button.image = NSImage(
                systemSymbolName: "calendar.badge.plus",
                accessibilityDescription: "ScheduleSage"
            )?.withSymbolConfiguration(configuration)
            
            button.image?.isTemplate = true
            
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
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
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self,
                  self.isPopoverShown,
                  let window = NSApp.windows.first(where: { $0.isKeyWindow }),
                  !NSPointInRect(event.locationInWindow, window.frame) else { return }
            
            self.dismissPopover()
        }
    }
    
    private func setupKeyboardMonitor() {
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
    
    // MARK: - Permissions
    private func requestPermissions() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.requestCalendarAccess() }
            group.addTask { await self.requestNotificationAccess() }
        }
    }
    
    private func requestCalendarAccess() async {
        do {
            let granted = try await calendarManager.requestAccess()
            logger.info("\(granted ? "Calendar access granted" : "Calendar access denied")")
        } catch {
            logger.error("Calendar access error: \(error.localizedDescription)")
        }
    }
    
    private func requestNotificationAccess() async {
        let granted = await notificationManager.requestAuthorization()
        logger.info("\(granted ? "Notification access granted" : "Notification access denied")")
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
        
        if window.isVisible {
            (window as? CustomMainWindow)?.closeWindow()
        } else {
            windowController?.showWindow(from: statusItem)
        }
    }
    
    private func toggleAddScheduleView() {
        guard let button = statusItem?.button else { return }
        
        if isPopoverShown {
            dismissPopover()
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.windows.first(where: { $0.isKeyWindow })?.level = .normal
        }
    }
    
    private func dismissPopover() {
        Task { @MainActor in
            viewModel?.handlePopoverDisappear()
            popover?.performClose(nil)
            isPopoverShown = false
        }
    }
}

// MARK: - NSPopoverDelegate
extension AppDelegate: NSPopoverDelegate {
    func popoverWillShow(_ notification: Notification) {
        isPopoverShown = true
    }
    
    func popoverWillClose(_ notification: Notification) {
        isPopoverShown = false
        viewModel?.handlePopoverDisappear()
    }
}

// MARK: - URL Handling
extension AppDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first,
              url.scheme == "schedulesage",
              url.host == "show",
              let button = statusItem?.button,
              !isPopoverShown else { return }
        
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

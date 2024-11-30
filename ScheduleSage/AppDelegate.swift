import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var popoverViewModel: PopoverViewModel!
    private var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "ScheduleSage")
            statusButton.action = #selector(togglePopover)
            statusButton.target = self
        }
    }
    
    private func setupPopover() {
        popoverViewModel = PopoverViewModel()
        popover = NSPopover()
        popover.contentSize = NSSize(
            width: ScheduleDesignSystem.Dimensions.containerWidth,
            height: ScheduleDesignSystem.Dimensions.containerHeight
        )
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(
            rootView: PopoverView()
                .environmentObject(popoverViewModel)
        )
    }
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let window = NSApp.windows.first(where: { $0.isKeyWindow }),
               !NSPointInRect(event.locationInWindow, window.frame) {
                self?.dismissPopover()
            }
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                dismissPopover()
            } else {
                popoverViewModel.resetState()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
                    window.level = .floating
                }
            }
        }
    }
    
    private func dismissPopover() {
        popover.performClose(nil)
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
} 
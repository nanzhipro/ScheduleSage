import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var popoverViewModel: PopoverViewModel!
    
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
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView()
                .environmentObject(popoverViewModel)
        )
    }
    
    private func setupEventMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismissPopover()
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                dismissPopover()
            } else {
                popoverViewModel.resetState()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    private func dismissPopover() {
        popover.performClose(nil)
    }
} 
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "ScheduleSage")
            statusButton.action = #selector(togglePopover)
            statusButton.target = self
        }
        
        // 配置 Popover
        popover = NSPopover()
        popover.contentSize = NSSize(
            width: ScheduleDesignSystem.Dimensions.containerWidth,
            height: ScheduleDesignSystem.Dimensions.containerHeight
        )
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView())
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
} 
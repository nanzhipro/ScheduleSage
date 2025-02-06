//
//  CustomMainWindow.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import AppKit
import SwiftUI

class CustomMainWindow: NSWindow {
    weak var viewModel: AddScheduleViewModel?
    private var visualEffectView: NSVisualEffectView?
    private var alwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop") {
        didSet {
            updateWindowLevel()
        }
    }
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, 
                  styleMask: [.closable, .miniaturizable, .borderless, .fullSizeContentView],
                  backing: .buffered,
                  defer: false)
        
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.hasShadow = true
        
        // 确保窗口层级在初始化时就正确设置
        updateWindowLevel()
        
        // 禁用全屏
        self.collectionBehavior = .fullScreenNone
        
        // 设置背景透明
        self.isOpaque = false
        self.backgroundColor = .clear
        
        // 设置关闭窗口的代理
        self.delegate = self
        
        // 设置视觉效果
        setupVisualEffectView()
        
        // 初始化时设置窗口为完全透明
        self.alphaValue = 0.0
        
        // 添加通知观察者
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowLevelChange),
            name: .windowLevelDidChange,
            object: nil
        )
    }
    
    @objc private func handleWindowLevelChange(_ notification: Notification) {
        if let isOnTop = notification.object as? Bool {
            self.alwaysOnTop = isOnTop
            self.level = isOnTop ? .floating : .normal
            if isVisible {
                self.orderFront(nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 添加公共关闭方法
    func closeWindow(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15  // 稍微缩短动画时间
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.viewModel?.handlePopoverDisappear()
            self?.close()
            completion?()
        })
    }
    
    private func setupVisualEffectView() {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .titlebar
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        
        // 确保视觉效果视图填充整个窗口
        if let contentView = contentView {
            visualEffectView.frame = contentView.bounds
            visualEffectView.autoresizingMask = [.width, .height]
            contentView.addSubview(visualEffectView, positioned: .below, relativeTo: nil)
        }
        
        self.visualEffectView = visualEffectView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupVisualEffectView()
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        // 确保窗口显示时应用正确的层级
        updateWindowLevel()
    }
    
    // 添加公开方法
    func refreshWindowLevel() {
        updateWindowLevel()
    }
    
    private func updateWindowLevel() {
        if alwaysOnTop {
            self.level = .floating
            self.collectionBehavior = .fullScreenNone
        } else {
            self.level = .normal
            self.collectionBehavior = .fullScreenNone
        }
        
        if isVisible {
            self.orderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - NSWindowDelegate
extension CustomMainWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // 通知 ViewModel 窗口即将关闭
        viewModel?.handlePopoverDisappear()
    }
}

class MainWindowController: NSWindowController {
    private var statusItemFrame: NSRect?
    
    convenience init(contentView: some View, viewModel: AddScheduleViewModel, size: NSSize) {
        let window = CustomMainWindow(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.closable, .miniaturizable, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.viewModel = viewModel
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        
        self.init(window: window)
    }
    
    func showWindow(from statusItem: NSStatusItem?) {
        guard let window = window else { return }
        
        // 设置窗口位置
        if let button = statusItem?.button,
           let frame = button.window?.convertToScreen(button.frame) {
            let padding: CGFloat = 5
            let targetOrigin = NSPoint(
                x: frame.origin.x - (window.frame.width - frame.width) / 2,
                y: frame.origin.y - window.frame.height - padding
            )
            
            window.setFrame(NSRect(
                origin: targetOrigin,
                size: window.frame.size
            ), display: false)
        } else {
            window.center()
        }
        
        // 设置初始透明度
        window.alphaValue = 0.0
        
        // 激活应用程序并使窗口成为活跃窗口
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        // 使用新的公开方法刷新窗口层级
        if let customWindow = window as? CustomMainWindow {
            customWindow.refreshWindowLevel()
        }
        
        // 执行淡入动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 1.0
        })
    }
    
    func closeWindow() {
        if let customWindow = window as? CustomMainWindow {
            customWindow.closeWindow()
        }
    }
}

extension Notification.Name {
    static let windowLevelDidChange = Notification.Name("windowLevelDidChange")
} 

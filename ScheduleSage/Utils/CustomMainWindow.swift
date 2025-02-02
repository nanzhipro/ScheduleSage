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
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, 
                  styleMask: [.closable, .miniaturizable, .borderless, .fullSizeContentView],
                  backing: .buffered,
                  defer: false)
        
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.hasShadow = true
        
        // 设置窗口层级为浮动层，保持在最上层
        self.level = .floating
        
        // 禁用全屏
        self.collectionBehavior = .fullScreenNone
        
        // 设置背景透明
        self.isOpaque = false
        self.backgroundColor = .clear
        
        // 设置关闭窗口的代理
        self.delegate = self
        
        // 设置视觉效果
        setupVisualEffectView()
    }
    
    // 添加公共关闭方法
    func closeWindow() {
        // 先通知 ViewModel
        viewModel?.handlePopoverDisappear()
        // 关闭窗口
        self.close()
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
}

// MARK: - NSWindowDelegate
extension CustomMainWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // 通知 ViewModel 窗口即将关闭
        viewModel?.handlePopoverDisappear()
    }
}

class MainWindowController: NSWindowController {
    convenience init(contentView: some View, viewModel: AddScheduleViewModel, size: NSSize) {
        let window = CustomMainWindow(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.closable, .miniaturizable, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 设置 ViewModel
        window.viewModel = viewModel
        
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView
        
        self.init(window: window)
    }
    
    // 添加公共关闭方法
    func closeWindow() {
        if let customWindow = window as? CustomMainWindow {
            customWindow.closeWindow()
        }
    }
} 

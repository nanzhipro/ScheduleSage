//
//  ScreenshotManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import Cocoa
import AppKit
import UniformTypeIdentifiers

/// ScreenshotManager
/// 窗口截图管理器
/// 提供窗口截图功能，支持将截图保存为PNG格式
public final class ScreenshotManager {
    
    // MARK: - Types
    
    public enum ScreenshotError: LocalizedError {
        case windowNotFound
        case screenshotFailed
        case saveFailed
        
        public var errorDescription: String? {
            switch self {
            case .windowNotFound: return "No valid window found"
            case .screenshotFailed: return "Failed to capture screenshot"
            case .saveFailed: return "Failed to save screenshot"
            }
        }
    }
    
    // MARK: - Properties
    
    public static let shared = ScreenshotManager()
    
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 截取当前窗口并保存
    /// - Parameter window: 目标窗口，如果为nil则使用当前活动窗口
    /// - Returns: 保存文件的URL路径或错误信息
    public func captureAndSave(_ window: NSWindow? = nil) -> Result<URL, ScreenshotError> {
        // 获取目标窗口
        guard let window = window ?? NSApplication.shared.mainWindow else {
            return .failure(.windowNotFound)
        }
        
        // 捕获窗口内容
        guard let image = captureWindow(window) else {
            return .failure(.screenshotFailed)
        }
        
        // 生成文件URL
        let filename = generateFilename(for: window)
        let fileURL = getDownloadsDirectory().appendingPathComponent(filename)
        
        // 保存图片
        return saveImage(image, to: fileURL)
    }
    
    /// 截取应用程序的所有窗口并保存
    /// - Returns: 保存文件的URL路径数组，每个元素对应一个窗口的截图结果
    public func captureAllWindows() -> [Result<URL, ScreenshotError>] {
        let windows = NSApplication.shared.windows
            .filter { !$0.title.contains("Item") }
        
        guard !windows.isEmpty else {
            return [.failure(.windowNotFound)]
        }
        
        return windows.map(captureAndSave)
    }
    
    // MARK: - Private Methods
    
    private func captureWindow(_ window: NSWindow) -> CGImage? {
        window.contentView?
            .bitmapImage()?
            .cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    private func generateFilename(for window: NSWindow) -> String {
        let timestamp = dateFormatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        
        let title = window.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        
        return "\(AppInfo.name)_Screenshot_\(title)_\(timestamp).png"
    }
    
    private func getDownloadsDirectory() -> URL {
        fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    }
    
    private func saveImage(_ image: CGImage, to url: URL) -> Result<URL, ScreenshotError> {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return .failure(.saveFailed)
        }
        
        CGImageDestinationAddImage(destination, image, nil)
        
        return CGImageDestinationFinalize(destination)
            ? .success(url)
            : .failure(.saveFailed)
    }
}

// MARK: - NSView Extension

private extension NSView {
    func bitmapImage() -> NSImage? {
        let scale = self.window?.backingScaleFactor ?? 1.0
        let size = self.bounds.size
        let pixelsWide = Int(size.width * scale)
        let pixelsHigh = Int(size.height * scale)
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: pixelsWide,
                                         pixelsHigh: pixelsHigh,
                                         bitsPerSample: 8,
                                         samplesPerPixel: 4,
                                         hasAlpha: true,
                                         isPlanar: false,
                                         colorSpaceName: .calibratedRGB,
                                         bitmapFormat: [],
                                         bytesPerRow: 0,
                                         bitsPerPixel: 0) else {
            return nil
        }
        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        if let context = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = context
            self.displayIgnoringOpacity(self.bounds, in: context)
            NSGraphicsContext.restoreGraphicsState()
            let image = NSImage(size: size)
            image.addRepresentation(rep)
            return image
        }
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
}

// MARK: - NSImage Extension

private extension NSImage {
    func with(representation rep: NSImageRep) -> NSImage {
        addRepresentation(rep)
        return self
    }
} 
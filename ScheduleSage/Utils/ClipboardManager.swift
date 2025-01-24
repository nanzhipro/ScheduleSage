//
//  ClipboardManager.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import AppKit

/// ClipboardManager 负责管理和处理系统剪贴板内容
/// 支持以下功能：
/// 1. 检测和读取剪贴板中的文件引用（图片文件和 URL）
/// 2. 检测和读取剪贴板中的图片数据
/// 3. 检测和读取剪贴板中的 URL 字符串
/// 4. 将图片数据保存为临时文件
@MainActor
class ClipboardManager: ObservableObject {
    /// 检查剪贴板内容并返回支持的内容类型
    /// - Returns: 如果找到支持的内容，返回 ClipboardContent；否则返回 nil
    func checkClipboard() -> ClipboardContent? {
        let pasteboard = NSPasteboard.general
        
        // 按优先级顺序检查剪贴板内容
        return checkFileURLs(in: pasteboard)    // 1. 检查文件引用
            ?? checkImageData(in: pasteboard)   // 2. 检查图片数据
            ?? checkURLString(in: pasteboard)   // 3. 检查 URL 字符串
    }
}

// MARK: - Private Helpers
private extension ClipboardManager {
    /// 检查剪贴板中的文件引用
    func checkFileURLs(in pasteboard: NSPasteboard) -> ClipboardContent? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let fileURL = urls.first else { return nil }
        
        // 优先检查是否为图片文件
        if ImageSupport.isSupported(url: fileURL) && FileManager.default.fileExists(atPath: fileURL.path) {
            return .image(fileURL)
        }
        
        // 检查是否为有效的 Web URL
        return fileURL.isValidWebURL ? .url(fileURL) : nil
    }
    
    /// 检查剪贴板中的图片数据
    func checkImageData(in pasteboard: NSPasteboard) -> ClipboardContent? {
        guard let image = NSImage(pasteboard: pasteboard) else { return nil }
        return saveImageToTemp(image).map { .image($0) }
    }
    
    /// 检查剪贴板中的 URL 字符串
    func checkURLString(in pasteboard: NSPasteboard) -> ClipboardContent? {
        guard let urlString = pasteboard.string(forType: .string),
              let url = URL(string: urlString),
              url.isValidWebURL else { return nil }
        return .url(url)
    }
    
    /// 将图片保存为临时文件
    /// - Parameter image: 要保存的图片
    /// - Returns: 保存成功返回文件 URL，失败返回 nil
    func saveImageToTemp(_ image: NSImage) -> URL? {
        // 转换图片为 PNG 数据
        guard let imageData = image.pngData else { return nil }
        
        // 创建临时文件 URL
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        // 保存文件
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}

// MARK: - NSImage Extension
private extension NSImage {
    /// 将 NSImage 转换为 PNG 数据
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData) else { return nil }
        return imageRep.representation(using: .png, properties: [:])
    }
}

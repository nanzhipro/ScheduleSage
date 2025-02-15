//
//  ImageSupport.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import UniformTypeIdentifiers

/// 图片支持
/// 统一管理应用支持的图片格式
enum ImageSupport {
    // MARK: - Supported Formats
    
    /// 支持的图片扩展名（小写）
    static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "webp"
    ]
    
    /// 支持的 MIME 类型
    static let supportedMimeTypes: Set<String> = [
        "image/jpeg",
        "image/png", 
        "image/heic",
        "image/webp"
    ]
    
    /// 支持的 UTTypes
    static let supportedUTTypes: [UTType] = [
        .jpeg,
        .png,
        .heic,
        .webP,
        // 注意：需要检查系统是否支持 WebP 的 UTType
        UTType("public.webp") ?? .png
    ]
    
    // MARK: - Validation Methods
    
    /// 检查文件扩展名是否支持
    /// - Parameter extension: 文件扩展名
    /// - Returns: 是否支持该格式
    static func isSupported(extension: String) -> Bool {
        supportedExtensions.contains(`extension`.lowercased())
    }
    
    /// 检查 URL 是否是支持的图片
    /// - Parameter url: 文件 URL
    /// - Returns: 是否支持该格式
    static func isSupported(url: URL) -> Bool {
        isSupported(extension: url.pathExtension)
    }
    
    /// 检查 MIME 类型是否支持
    /// - Parameter mimeType: MIME 类型
    /// - Returns: 是否支持该格式
    static func isSupported(mimeType: String) -> Bool {
        supportedMimeTypes.contains(mimeType.lowercased())
    }
}

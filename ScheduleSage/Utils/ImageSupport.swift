//
//  ImageSupport.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import UniformTypeIdentifiers

enum ImageSupport {
  /// 支持的图片类型
  static let supportedExtensions = ["jpg", "jpeg", "png", "heic"]

  /// UTType 类型定义
  static let supportedUTTypes: [UTType] = [
    .jpeg,
    .png,
    .heic,
  ]

  /// 检查文件扩展名是否支持
  static func isSupported(extension: String) -> Bool {
    supportedExtensions.contains(`extension`.lowercased())
  }

  /// 检查 URL 是否是支持的图片
  static func isSupported(url: URL) -> Bool {
    isSupported(extension: url.pathExtension)
  }
}

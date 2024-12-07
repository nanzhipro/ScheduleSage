//
//  ImageLoader.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import AppKit
import Foundation

protocol ImageLoading {
  func loadImage(from url: URL) async throws -> NSImage
  func loadAndSaveImage(from url: URL) async throws -> String
}

final class ImageLoader: ImageLoading {
  // MARK: - Properties
  private let session: URLSession
  private let supportedMimeTypes = ["image/jpeg", "image/png", "image/gif", "image/heic"]
  private let tempDirectory: URL

  // MARK: - Initialization
  init(
    configuration: URLSessionConfiguration = .default,
    tempDirectory: URL = FileManager.default.temporaryDirectory
  ) {
    self.session = URLSession(configuration: configuration)
    self.tempDirectory = tempDirectory
  }

  // MARK: - Public Methods
  func loadImage(from url: URL) async throws -> NSImage {
    let (data, response) = try await session.data(from: url)

    // 验证响应
    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw ImageLoadError.invalidResponse
    }

    // 验证 MIME 类型
    if let mimeType = httpResponse.mimeType,
      !supportedMimeTypes.contains(mimeType)
    {
      throw ImageLoadError.unsupportedImageFormat
    }

    // 创建图片
    guard let image = NSImage(data: data) else {
      throw ImageLoadError.invalidImageData
    }

    return image
  }

  func loadAndSaveImage(from url: URL) async throws -> String {
    let image = try await loadImage(from: url)

    // 创建临时文件路径
    let fileName = "\(UUID().uuidString).\(url.pathExtension)"
    let fileURL = tempDirectory.appendingPathComponent(fileName)

    // 保存图片
    guard let tiffData = image.tiffRepresentation,
      let imageRep = NSBitmapImageRep(data: tiffData),
      let imageData = imageRep.representation(using: .jpeg, properties: [:])
    else {
      throw ImageLoadError.invalidImageData
    }

    try imageData.write(to: fileURL)
    return fileURL.path
  }
}

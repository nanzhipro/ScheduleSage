//
//  ImageFetcher.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import AppKit
import Kingfisher

protocol ImageFetching {
  func fetchImage(from url: URL) async throws -> String
}

final class ImageFetcher: ImageFetching {
  private let tempDirectory: URL

  init(tempDirectory: URL = FileManager.default.temporaryDirectory) {
    self.tempDirectory = tempDirectory
  }

  func fetchImage(from url: URL) async throws -> String {
    // 使用 Kingfisher 下载图片
    let imageData = try await withCheckedThrowingContinuation { continuation in
      KingfisherManager.shared.retrieveImage(with: url) { result in
        switch result {
        case .success(let imageResult):
          if let data = imageResult.image.tiffRepresentation {
            continuation.resume(returning: data)
          } else {
            // 使用自定义错误
            continuation.resume(throwing: ImageLoadError.invalidImageData)
          }
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }

    // 保存到临时文件
    let fileName = "\(UUID().uuidString).jpg"
    let fileURL = tempDirectory.appendingPathComponent(fileName)

    do {
      try imageData.write(to: fileURL)
      return fileURL.path
    } catch {
      throw ImageLoadError.invalidImageData
    }
  }
}

//// MARK: - Error Types
//private enum ImageLoadError: LocalizedError {
//    case invalidImageData
//
//    var errorDescription: String? {
//        switch self {
//        case .invalidImageData:
//            return "无法处理图片数据"
//        }
//    }
//}

//
//  ImageLoadError.swift
//  ScheduleSage
//
//  Created by 南朋友 on 2024/03/26.
//

import Foundation

enum ImageLoadError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case invalidImageData
    case unsupportedImageFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的图片 URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的服务器响应"
        case .invalidImageData:
            return "无效的图片数据"
        case .unsupportedImageFormat:
            return "不支持的图片格式"
        }
    }
} 
//
//  Typography.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-25.
//

import SwiftUI

extension DesignSystem {
  /// 排版系统
  enum Typography {
    /// 页面标题字体
    /// 用于页面主标题，17pt 中等粗细
    static let headerTitle = Font.system(size: 17, weight: .medium)
    
    /// 大号正文字体
    /// 用于重要内容，15pt 常规粗细
    static let bodyLarge = Font.system(size: 15)
    
    /// 常规正文字体
    /// apple主题13pt，其他14pt
    static var bodyRegular: Font {
      .system(size: currentTheme == .apple ? 13 : 14)
    }
    
    /// 中等正文字体
    /// 用于重要的正文内容，14pt 中等粗细
    static let bodyMedium = Font.system(size: 14, weight: .medium)
    
    /// 表单标签字体
    /// 用于表单字段标签，14pt
    static let formLabel = Font.system(size: 14)
    
    /// 按钮文字字体
    /// 用于按钮文字，15pt
    static let buttonLabel = Font.system(size: 15)
    
    /// 事件标题字体
    /// 用于事件卡片标题，16pt 中等粗细
    static let eventTitle = Font.system(size: 16, weight: .medium)
    
    /// 事件时间字体
    /// 用于显示事件时间，14pt
    static let eventTime = Font.system(size: 14)
    
    /// 事件计数字体
    /// 用于显示事件数量，13pt
    static let eventCount = Font.system(size: 13)
    
    /// 状态文本字体
    /// 用于显示状态信息，13pt
    static let statusText = Font.system(size: 13)
    
    /// 空状态标题字体
    /// 用于空列表等状态的标题，15pt 中等粗细
    static let emptyStateTitle = Font.system(size: 15, weight: .medium)
    
    /// 方法标签字体
    /// 用于显示方法名称，13pt
    static let methodLabel = Font.system(size: 13)
    
    /// 说明文本字体
    /// 用于辅助说明文本，12pt
    static let caption = Font.system(size: 12)
    
    /// 大标题字体
    /// 用于主要标题，24pt 半粗体
    static let title = Font.system(size: 24, weight: .semibold)
    
    /// 导航文本字体
    /// 用于导航栏文本，13pt 中等粗细
    static let navigationText = Font.system(size: 13, weight: .medium)
    
    /// 大页面标题字体
    /// 用于宽页面(640px)的主标题，20pt 半粗体
    static let largeHeaderTitle = Font.system(size: 20, weight: .semibold)
    
    /// 大页面副标题字体
    /// 用于宽页面的副标题，14pt
    static let largeHeaderSubtitle = Font.system(size: 14)
  }
} 
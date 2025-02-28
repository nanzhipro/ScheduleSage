//
//  Dimensions.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-25.
//

import SwiftUI

extension DesignSystem {
  /// 尺寸系统
  enum Dimensions {
    /// 容器宽度
    static let containerWidth: CGFloat = 440
    /// 容器高度
    static let containerHeight: CGFloat = 563
    /// 确认页面高度
    static let confirmPageHeight: CGFloat = 550
    /// 容器圆角半径
    static let containerCornerRadius: CGFloat = 12
    /// 卡片圆角半径
    static let cardCornerRadius: CGFloat = 8
    /// 按钮圆角半径
    static let buttonCornerRadius: CGFloat = 8
    /// 头部圆角半径
    static let headerCornerRadius: CGFloat = 8
    /// 头部高度
    static let headerHeight: CGFloat = 56
    /// 表单字段高度
    static let formFieldHeight: CGFloat = 44
    /// 按钮高度
    static let buttonHeight: CGFloat = 44
    /// 列表头部高度
    static let listHeaderHeight: CGFloat = 44
    /// 状态图标尺寸
    static let statusIconSize: CGFloat = 24
    /// 方法图标尺寸
    static let methodIconSize: CGFloat = 32
    /// 添加按钮尺寸
    static let addButtonSize: CGFloat = 28
    /// 皇冠图标尺寸
    static let crownIconSize: CGFloat = 24
    /// 空状态图标尺寸
    static let emptyStateIconSize: CGFloat = 80
    /// 事件图标尺寸
    static let eventIconSize: CGFloat = 32
    /// 事件卡片高度
    static let eventCardHeight: CGFloat = 134
    /// 事件卡片间距
    static let eventCardSpacing: CGFloat = 12
    /// 选择指示器外圈尺寸
    static let selectionIndicatorOuterSize: CGFloat = 16
    /// 选择指示器中圈尺寸
    static let selectionIndicatorMiddleSize: CGFloat = 12
    /// 选择指示器内圈尺寸
    static let selectionIndicatorInnerSize: CGFloat = 8
    /// 列表内容间距
    static let listContentSpacing: CGFloat = 16
    /// 列表垂直内边距
    static let listVerticalPadding: CGFloat = 20
    /// 设置按钮尺寸
    static let settingsButtonSize: CGFloat = 22
    
    /// 主页面宽度
    static let mainViewWidth: CGFloat = 800
    /// 主页面高度
    static let mainViewHeight: CGFloat = 580
    /// 事件列表页宽度
    static let eventListWidth: CGFloat = mainViewWidth * 0.8  // 640
    /// 事件列表页高度
    static let eventListHeight: CGFloat = mainViewHeight * 0.8  // 512
    
    /// 大尺寸方法按钮图标
    static let largeMethodIconSize: CGFloat = 40  // 增大图标尺寸
    
    /// 大尺寸按钮高度
    static let largeButtonHeight: CGFloat = 52  // 增大按钮高度
  }
} 
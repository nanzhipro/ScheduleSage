//
//  AnimationStates.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 水波纹动画状态
/// 用于管理语音按钮的水波纹动画效果
public struct RippleState: Identifiable {
  public let id: UUID
  public var scale: CGFloat
  public var opacity: Double

  public init(id: UUID = UUID(), scale: CGFloat, opacity: Double) {
    self.id = id
    self.scale = scale
    self.opacity = opacity
  }
}

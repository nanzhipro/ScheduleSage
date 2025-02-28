//
//  Colors.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-25.
//

import SwiftUI

extension DesignSystem {
  /// 颜色系统
  enum Colors {
    /// 品牌主色
    /// - apple: iOS蓝
    /// - wechat: 微信绿
    /// - airbnb: 珊瑚红
    static var primary: Color {
      switch currentTheme {
      case .apple: return Color(light: "007AFF", dark: "0A84FF")
      case .wechat: return Color(light: "07C160", dark: "07C160")
      case .airbnb: return Color(light: "FF5A5F", dark: "FF5A5F")
      }
    }

    /// 次要品牌色
    /// 用于次要强调、辅助元素等
    static var secondary: Color {
      switch currentTheme {
      case .apple: return Color(light: "5856D6", dark: "5E5CE6")
      case .wechat: return Color(light: "576B95", dark: "576B95")
      case .airbnb: return Color(light: "00A699", dark: "00A699")
      }
    }

    /// 主要背景色
    /// 用于应用的主要背景，确保内容清晰可见
    static var primaryBackground: Color {
      switch currentTheme {
      case .apple: return Color(light: "F5F5F7", dark: "242424")
      case .wechat: return Color(light: "F7F7F7", dark: "242424")
      case .airbnb: return Color(light: "F7F7F7", dark: "1D1D1D")
      }
    }

    /// 基础背景色
    /// 用于卡片、弹窗等组件的背景
    static var background: Color {
      let (light, dark) = currentTheme == .airbnb 
        ? ("FFFFFF", "222222") 
        : ("FFFFFF", "1E1E1E")
      return Color(light: light, dark: dark)
    }

    /// 次要灰色
    /// 用于次要信息、图标等
    static var secondaryGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "86868B", dark: "98989F")
      case .wechat: return Color(light: "9B9B9B", dark: "98989F")
      case .airbnb: return Color(light: "717171", dark: "B0B0B0")
      }
    }

    /// 浅灰色
    /// 用于背景、分割线等装饰性元素
    static var lightGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "F2F2F7", dark: "2C2C2E")
      case .wechat: return Color(light: "F7F7F7", dark: "2C2C2E")
      case .airbnb: return Color(light: "F7F7F7", dark: "2D2D2D")
      }
    }

    /// 容器灰色
    /// 用于容器、卡片等组件的背景
    static var containerGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "F8F8FA", dark: "333333")
      case .wechat: return Color(light: "F8F8F8", dark: "333333")
      case .airbnb: return Color(light: "F8F8F8", dark: "2A2A2A")
      }
    }

    /// 边框灰色
    /// 用于边框、分割线等
    static var borderGray: Color {
      switch currentTheme {
      case .apple: return Color(light: "E5E5E5", dark: "424242")
      case .wechat: return Color(light: "EBEDF0", dark: "424242")
      case .airbnb: return Color(light: "DDDDDD", dark: "3D3D3D")
      }
    }

    /// 成功状态颜色
    /// 用于成功提示、完成状态等
    static var success: Color {
      currentTheme == .airbnb 
        ? Color(light: "008A05", dark: "00A306") 
        : primary
    }

    /// 错误状态颜色
    /// 用于错误提示、警告状态等
    static var error: Color {
      switch currentTheme {
      case .apple: return Color(light: "FF3B30", dark: "FF453A")
      case .wechat: return Color(light: "FA5151", dark: "FA5151")
      case .airbnb: return Color(light: "C13515", dark: "E31C1C")
      }
    }

    /// 主要文本颜色
    /// 用于标题、正文等主要文本
    static var primaryText: Color {
      switch currentTheme {
      case .apple: return Color(light: "000000", dark: "FFFFFF")
      case .wechat: return Color(light: "2C2C2C", dark: "FFFFFF")
      case .airbnb: return Color(light: "222222", dark: "FFFFFF")
      }
    }

    /// 次要文本颜色
    /// 用于描述、说明等次要文本
    static var secondaryText: Color {
      switch currentTheme {
      case .apple: return Color(light: "86868B", dark: "98989F")
      case .wechat: return Color(light: "9B9B9B", dark: "98989F")
      case .airbnb: return Color(light: "717171", dark: "A0A0A0")
      }
    }

    /// 第三级文本颜色
    /// 用于辅助性文本、占位符等
    static var tertiaryText: Color {
      switch currentTheme {
      case .apple: return Color(light: "C7C7CC", dark: "48484A")
      case .wechat: return Color(light: "BFBFBF", dark: "48484A")
      case .airbnb: return Color(light: "BFBFBF", dark: "4A4A4A")
      }
    }

    /// 取消按钮背景色
    /// 用于取消、返回等次要操作按钮
    static var cancelButtonBackground: Color {
      Color(hex: currentTheme == .apple ? "F5F5F5" : "F7F7F7")
    }

    /// 图标灰色
    /// 用于常规状态的图标
    static var iconGray: Color {
      switch currentTheme {
      case .apple: return Color(hex: "666666")
      case .wechat: return Color(hex: "8F8F8F")
      case .airbnb: return Color(hex: "717171")
      }
    }

    /// 链接颜色
    /// 用于可点击的文本链接
    static var link: Color {
      switch currentTheme {
      case .apple: return Color(hex: "007AFF")
      case .wechat: return Color(hex: "576B95")
      case .airbnb: return Color(hex: "FF5A5F")
      }
    }

    /// 次要背景色
    /// 用于次级页面或组件的背景
    static var secondaryBackground: Color {
      Color(light: "FFFFFF", dark: "2C2C2C")
    }

    /// 卡片背景色
    /// 用于卡片组件的背景
    static var cardBackground: Color {
      Color(light: "FFFFFF", dark: "2A2A2A")
    }

    /// 悬停背景色
    /// 用于元素悬停状态
    static var hoverBackground: Color {
      switch currentTheme {
      case .apple: return Color(light: "F5F5F7", dark: "3A3A3A")
      case .wechat: return Color(light: "F7F7F7", dark: "3A3A3A")
      case .airbnb: return Color(light: "F8F8F8", dark: "3A3A3A")
      }
    }

    /// 分割线颜色
    /// 用于列表项分割、边框等
    static var separator: Color {
      switch currentTheme {
      case .apple: return Color(light: "E5E5E5", dark: "3D3D3D")
      case .wechat: return Color(light: "EBEDF0", dark: "3D3D3D")
      case .airbnb: return Color(light: "EBEBEB", dark: "3D3D3D")
      }
    }

    // MARK: - Gradient Colors
    
    /// 深色模式渐变色 - 顶部
    static let darkGradientTop = Color(
      light: "F5F5F7",  // 浅色模式下不使用
      dark: "151516"    // rgb(21, 21, 22)
    )
    
    /// 深色模式渐变色 - 中间
    static let darkGradientMiddle = Color(
      light: "F7F7F7",  // 浅色模式下不使用
      dark: "181819"    // rgb(24, 24, 25)
    )
    
    /// 浅色模式渐变色 - 顶部
    static let lightGradientTop = Color(
      light: "F5F7F8",  // rgb(245, 247, 248)
      dark: "242424"    // 深色模式下不使用
    )
    
    /// 浅色模式渐变色 - 中间
    static let lightGradientMiddle = Color(
      light: "F7F8F9",  // rgb(247, 248, 249)
      dark: "242424"    // 深色模式下不使用
    )
  }
} 
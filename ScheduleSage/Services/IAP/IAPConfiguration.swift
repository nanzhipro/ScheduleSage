//
//  IAPConfiguration.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import Foundation
import RevenueCat

/// IAP Configuration
/// 内购配置
struct IAPConfiguration {
    /// RevenueCat API Key
    static var apiKey: String {
        // TODO: 从服务端获取
        return "appl_dMdpmzBEXIUFoVMfBQkSmpLDALP"
    }
    
    /// 对应 RevenueCat 中的产品Identifier，且对应App Store Connect中的产品ID
    // 周订阅
    static let weeklySubscriptionId = "com.tiwenlab.schedulesage.weekly"
    // 月订阅
    static let monthlySubscriptionId = "com.tiwenlab.schedulesage.monthly"
    // 年订阅
    static let yearlySubscriptionId = "com.tiwenlab.schedulesage.yearly2"
    
    /// 权限标识符： 必须和 RevenueCat 中的权限标识符一致
    /// 见：https://app.revenuecat.com/projects/d74a0317/entitlements
    static let premiumEntitlementId = "pro_user"
}


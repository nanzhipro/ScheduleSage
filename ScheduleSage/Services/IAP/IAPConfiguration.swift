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
        #if DEBUG
        return "appl_dMdpmzBEXIUFoVMfBQkSmpLDALP"
        #else
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else {
            fatalError("RevenueCat API Key not found")
        }
        return apiKey
        #endif
    }
    
    /// 产品标识符
    #if os(iOS)
    static let monthlySubscriptionId = "com.schedulesage.ios.subscription.monthly"
    static let yearlySubscriptionId = "com.schedulesage.ios.subscription.yearly"
    #elseif os(macOS)
    static let monthlySubscriptionId = "com.schedulesage.macos.subscription.monthly"
    static let yearlySubscriptionId = "com.schedulesage.macos.subscription.yearly"
    #endif
    
    /// 权限标识符： 必须和 RevenueCat 中的权限标识符一致
    /// 见：https://app.revenuecat.com/projects/d74a0317/entitlements
    static let premiumEntitlementId = "pro_user"
}


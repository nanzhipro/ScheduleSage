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
    // RevenueCat API Key
    static var apiKey: String {
        // 从配置文件或环境变量获取
        #if DEBUG
        return "appl_dMdpmzBEXIUFoVMfBQkSmpLDALP"
        #else
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else {
            fatalError("RevenueCat API Key not found")
        }
        return apiKey
        #endif
    }
    
    // 配置选项
    static let configuration: RevenueCat.Configuration = {
        var builder = RevenueCat.Configuration.Builder(withAPIKey: apiKey)
        
        // 基本配置
        builder = builder
            .with(networkTimeout: 30)
            .with(dangerousSettings: DangerousSettings(autoSyncPurchases: true))
        
        // 平台特定配置
        #if os(iOS)
        builder = builder.with(
            purchasesAreCompletedBy: .revenueCat,
            storeKitVersion: .storeKit2
        )
        #elseif os(macOS)
        builder = builder.with(
            purchasesAreCompletedBy: .revenueCat,
            storeKitVersion: .storeKit2
        )
        #endif
        
        return builder.build()
    }()
    
    // Product IDs - 使用平台特定的标识符
    #if os(iOS)
    static let monthlySubscriptionId = "com.schedulesage.ios.subscription.monthly"
    static let yearlySubscriptionId = "com.schedulesage.ios.subscription.yearly"
    #elseif os(macOS)
    static let monthlySubscriptionId = "com.schedulesage.macos.subscription.monthly"
    static let yearlySubscriptionId = "com.schedulesage.macos.subscription.yearly"
    #endif
    
    // Entitlement IDs
    static let premiumEntitlementId = "premium_features"
    
    // Offering IDs
    struct Offerings {
        static let defaultOffering = "default"
        static let specialOffering = "special_promotion"
        
        #if os(iOS)
        static let platformSpecificOffering = "ios_special"
        #elseif os(macOS)
        static let platformSpecificOffering = "macos_special"
        #endif
    }
    
    // Feature Flags
    static let shouldShowIntroductoryOffer = true
    static let maxRestoreAttempts = 3
    
    // Platform specific settings
    static let platformSpecificSettings = PlatformSettings()
}

/// Platform specific settings
struct PlatformSettings {
    let showPromotionalOffers: Bool
    let useStoreKit2: Bool
    let purchaseCompletion: PurchaseCompletion
    
    init() {
        #if os(iOS)
        self.showPromotionalOffers = true
        self.useStoreKit2 = true
        self.purchaseCompletion = .revenueCat
        #elseif os(macOS)
        self.showPromotionalOffers = false
        self.useStoreKit2 = true
        self.purchaseCompletion = .revenueCat
        #endif
    }
}

/// Purchase completion type
enum PurchaseCompletion {
    case revenueCat         // 由 RevenueCat 处理购买
    case myApp             // 由应用自己处理购买
} 
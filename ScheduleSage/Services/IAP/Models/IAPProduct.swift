//
//  IAPProduct.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import Foundation
import RevenueCat

/// Subscription Product Model
/// 订阅产品模型
struct IAPProduct: Identifiable {
    let id: String
    let package: Package
    let title: String
    let description: String
    let price: String
    let period: String
    let isPopular: Bool
    let features: [String]
    let introductoryPrice: String?
    let introductoryPeriod: String?
    let hasFreeTrial: Bool
    
    init(package: Package, isPopular: Bool = false) {
        self.id = package.identifier
        self.package = package
        self.title = package.storeProduct.localizedTitle
        self.description = package.storeProduct.localizedDescription
        self.price = package.localizedPriceString
        self.period = Self.formatPeriod(package.storeProduct.subscriptionPeriod)
        self.isPopular = isPopular
        self.features = Self.getFeaturesForProduct(package.identifier)
        
        if let intro = package.storeProduct.introductoryDiscount {
            self.introductoryPrice = intro.localizedPriceString
            self.introductoryPeriod = Self.formatPeriod(intro.subscriptionPeriod)
            self.hasFreeTrial = intro.price == 0
        } else {
            self.introductoryPrice = nil
            self.introductoryPeriod = nil
            self.hasFreeTrial = false
        }
    }
    
    private static func formatPeriod(_ period: SubscriptionPeriod?) -> String {
        guard let period = period else { return "" }
        
        switch period.unit {
        case .month:
            return period.value == 1 ? 
                NSLocalizedString("subscription_period_monthly", comment: "") :
                String(format: NSLocalizedString("subscription_period_months", comment: ""), period.value)
        case .year:
            return period.value == 1 ? 
                NSLocalizedString("subscription_period_yearly", comment: "") :
                String(format: NSLocalizedString("subscription_period_years", comment: ""), period.value)
        default:
            return ""
        }
    }
    
    private static func getFeaturesForProduct(_ identifier: String) -> [String] {
        switch identifier {
        case IAPConfiguration.monthlySubscriptionId:
            return [
                "subscription_feature_unlimited_usage",
                "subscription_feature_premium_features",
                "subscription_feature_priority_support"
            ].map { NSLocalizedString($0, comment: "") }
        case IAPConfiguration.yearlySubscriptionId:
            return [
                "subscription_feature_unlimited_usage",
                "subscription_feature_premium_features",
                "subscription_feature_priority_support",
                "subscription_feature_yearly_discount"
            ].map { NSLocalizedString($0, comment: "") }
        default:
            return []
        }
    }
    
    var formattedPrice: String {
        if let introPrice = introductoryPrice, hasFreeTrial {
            return String(format: NSLocalizedString("free_trial_then_price", comment: ""), introductoryPeriod ?? "", price)
        } else {
            return price
        }
    }
} 
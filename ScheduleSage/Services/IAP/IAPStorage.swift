//
//  IAPStorage.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import Foundation

/// IAP Storage
/// 内购存储
struct IAPStorage {
    private static let defaults = UserDefaults.standard
    
    private enum Keys {
        static let lastPurchaseDate = "iap_last_purchase_date"
        static let purchaseHistory = "iap_purchase_history"
        static let subscriptionExpiryDate = "iap_subscription_expiry_date"
    }
    
    static func saveLastPurchaseDate(_ date: Date) {
        defaults.set(date, forKey: Keys.lastPurchaseDate)
    }
    
    static func getLastPurchaseDate() -> Date? {
        defaults.object(forKey: Keys.lastPurchaseDate) as? Date
    }
    
    static func savePurchaseHistory(_ productId: String) {
        var history = getPurchaseHistory()
        history.append(PurchaseRecord(productId: productId, date: Date()))
        if let encoded = try? JSONEncoder().encode(history) {
            defaults.set(encoded, forKey: Keys.purchaseHistory)
        }
    }
    
    static func getPurchaseHistory() -> [PurchaseRecord] {
        guard let data = defaults.data(forKey: Keys.purchaseHistory),
              let history = try? JSONDecoder().decode([PurchaseRecord].self, from: data) else {
            return []
        }
        return history
    }
    
    static func saveSubscriptionExpiryDate(_ date: Date?) {
        defaults.set(date, forKey: Keys.subscriptionExpiryDate)
    }
    
    static func getSubscriptionExpiryDate() -> Date? {
        defaults.object(forKey: Keys.subscriptionExpiryDate) as? Date
    }
}

struct PurchaseRecord: Codable {
    let productId: String
    let date: Date
} 
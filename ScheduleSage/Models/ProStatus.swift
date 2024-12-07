//
//  ProStatus.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import Foundation

// MARK: - Pro Status Model
struct ProStatus {
  // MARK: - Supporting Types
  enum ProTier: String, Codable {
    case free
    case basic
    case pro
    case enterprise
  }

  enum BillingPeriod: String, Codable {
    case monthly
    case quarterly
    case yearly
    case lifetime
  }

  enum AccountStatus: String, Codable {
    case active
    case suspended
    case cancelled
    case expired
    case inGracePeriod
  }

  // MARK: - Properties
  let userId: String
  let isPro: Bool
  let tier: ProTier
  let remainingUses: Int?
  let totalUsageCount: Int
  let dailyUsageLimit: Int?
  let subscriptionId: String?
  let purchaseDate: Date?
  let expiryDate: Date?
  let autoRenewal: Bool
  let gracePeriodEndDate: Date?
  let features: [ProFeature]
  let customFeatureFlags: [String: Bool]
  let lastPaymentDate: Date?
  let nextBillingDate: Date?
  let billingPeriod: BillingPeriod?
  let price: Decimal?
  let currency: String?
  let isInGracePeriod: Bool
  let isTrialUsed: Bool
  let accountStatus: AccountStatus
}

// MARK: - Codable Implementation
extension ProStatus: Codable {
  private enum CodingKeys: String, CodingKey {
    case userId, isPro, tier
    case remainingUses, totalUsageCount, dailyUsageLimit
    case subscriptionId, purchaseDate, expiryDate, autoRenewal, gracePeriodEndDate
    case features, customFeatureFlags
    case lastPaymentDate, nextBillingDate, billingPeriod, price, currency
    case isInGracePeriod, isTrialUsed, accountStatus
  }
}

// MARK: - Factory Methods
extension ProStatus {
  static let unlimited: Self = {
    ProStatus(
      userId: "",
      isPro: true,
      tier: .pro,
      remainingUses: nil,
      totalUsageCount: 0,
      dailyUsageLimit: nil,
      subscriptionId: "pro_unlimited",
      purchaseDate: Date(),
      expiryDate: nil,
      autoRenewal: true,
      gracePeriodEndDate: nil,
      features: ProFeature.allFeatures,
      customFeatureFlags: [:],
      lastPaymentDate: Date(),
      nextBillingDate: nil,
      billingPeriod: .yearly,
      price: 99,
      currency: "CNY",
      isInGracePeriod: false,
      isTrialUsed: true,
      accountStatus: .active
    )
  }()

  static func free(remainingUses: Int) -> Self {
    ProStatus(
      userId: "",
      isPro: false,
      tier: .free,
      remainingUses: remainingUses,
      totalUsageCount: 0,
      dailyUsageLimit: 5,
      subscriptionId: nil,
      purchaseDate: nil,
      expiryDate: nil,
      autoRenewal: false,
      gracePeriodEndDate: nil,
      features: ProFeature.freeFeatures,
      customFeatureFlags: [:],
      lastPaymentDate: nil,
      nextBillingDate: nil,
      billingPeriod: nil,
      price: nil,
      currency: nil,
      isInGracePeriod: false,
      isTrialUsed: false,
      accountStatus: .active
    )
  }
}

// MARK: - Helper Methods
extension ProStatus {
  var isActive: Bool {
    accountStatus == .active && !isInGracePeriod
  }

  var canUseProFeatures: Bool {
    isPro && isActive
  }

  func hasFeature(_ featureId: String) -> Bool {
    features.contains { $0.id == featureId } || customFeatureFlags[featureId] == true
  }
}

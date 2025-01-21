import Foundation

struct SubscriptionStatus: Codable {
    let isActive: Bool
    let expirationDate: Date?
    let productIdentifier: String?
    let isTrial: Bool
    let isIntroOffer: Bool
    let isRenewing: Bool
    let willRenew: Bool
    let isInGracePeriod: Bool
    let isInBillingRetryPeriod: Bool
    let unsubscribeDetectedAt: Date?
    let billingIssueDetectedAt: Date?
}

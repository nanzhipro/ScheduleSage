import Foundation
import RevenueCat

class SubscriptionViewModel: ObservableObject {
    @Published var isSubscribed: Bool = false

    func purchaseSubscription() {
        Purchases.shared.purchasePackage("your_package_identifier") { (transaction, customerInfo, error, userCancelled) in
            if let error = error {
                print("Purchase failed: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                self.isSubscribed = customerInfo.entitlements.all["your_entitlement_identifier"]?.isActive == true
            }
        }
    }

    func restorePurchases() {
        Purchases.shared.restoreTransactions { (customerInfo, error) in
            if let error = error {
                print("Restore failed: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                self.isSubscribed = customerInfo.entitlements.all["your_entitlement_identifier"]?.isActive == true
            }
        }
    }

    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let error = error {
                print("Failed to fetch customer info: \(error.localizedDescription)")
            } else if let customerInfo = customerInfo {
                self.isSubscribed = customerInfo.entitlements.all["your_entitlement_identifier"]?.isActive == true
            }
        }
    }
}

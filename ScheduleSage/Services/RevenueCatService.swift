import Foundation
import RevenueCat

class RevenueCatService {
    
    static let shared = RevenueCatService()
    
    private init() {}
    
    func purchaseProduct(productIdentifier: String, completion: @escaping (Result<Purchase, Error>) -> Void) {
        Purchases.shared.purchasePackage(productIdentifier) { (transaction, customerInfo, error, userCancelled) in
            if let error = error {
                completion(.failure(error))
            } else if let customerInfo = customerInfo {
                completion(.success(customerInfo))
            }
        }
    }
    
    func restorePurchases(completion: @escaping (Result<CustomerInfo, Error>) -> Void) {
        Purchases.shared.restoreTransactions { (customerInfo, error) in
            if let error = error {
                completion(.failure(error))
            } else if let customerInfo = customerInfo {
                completion(.success(customerInfo))
            }
        }
    }
    
    func checkSubscriptionStatus(completion: @escaping (Result<CustomerInfo, Error>) -> Void) {
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            if let error = error {
                completion(.failure(error))
            } else if let customerInfo = customerInfo {
                completion(.success(customerInfo))
            }
        }
    }
}

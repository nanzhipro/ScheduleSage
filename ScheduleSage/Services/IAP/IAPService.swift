//
//  IAPService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import Foundation
import RevenueCat
import Combine
import StoreKit

/// 内购服务
/// 负责管理应用内购买、订阅状态和产品展示
///
/// 使用单例模式确保全局唯一实例：
/// ```swift
/// let iapService = IAPService.shared
/// ```
class IAPService: NSObject, ObservableObject {
    /// 共享实例
    static let shared = IAPService()
    
    // MARK: - Published Properties
    
    /// 当前用户的订阅信息
    @Published private(set) var customerInfo: CustomerInfo?
    
    /// 可用的产品组合
    @Published private(set) var offerings: Offerings?
    
    /// 可购买的产品列表
    @Published private(set) var products: [IAPProduct] = []
    
    /// 当前激活的订阅
    @Published private(set) var currentSubscription: IAPProduct?
    
    /// 购买状态
    @Published private(set) var purchaseState: PurchaseState = .idle
    
    /// 最近的错误信息
    @Published private(set) var error: IAPError?
    
    /// 订阅状态
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .loading
    
    /// 用于存储取消令牌的集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    private override init() {
        super.init()
        configureSDK()
        setupSubscriptionMonitoring()
        fetchOfferings()
    }
    
    // MARK: - 配置方法
    
    /// 配置 RevenueCat SDK
    private func configureSDK() {
        Purchases.logLevel = .debug
        Purchases.configure(with: IAPConfiguration.configuration)
        
        #if os(iOS)
        setupiOSSpecificFeatures()
        #endif
    }
    
    #if os(iOS)
    /// 设置 iOS 特定功能
    private func setupiOSSpecificFeatures() {
        if IAPConfiguration.platformSpecificSettings.showPromotionalOffers {
            // 配置促销优惠
        }
    }
    #endif
    
    /// 设置订阅状态监控
    private func setupSubscriptionMonitoring() {
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                await updateCustomerInfo(customerInfo)
            }
        }
        Purchases.shared.delegate = self
    }
    
    // MARK: - 数据管理
    
    /// 获取可用的产品组合
    private func fetchOfferings() {
        Task {
            do {
                let offerings = try await Purchases.shared.offerings()
                await updateOfferings(offerings)
            } catch {
                await updateError(.productNotFound)
            }
        }
    }
    
    /// 更新用户订阅信息
    /// - Parameter info: 新的用户信息
    @MainActor
    private func updateCustomerInfo(_ info: CustomerInfo) {
        customerInfo = info
        updateSubscriptionStatus(info)
        
        if let expirationDate = info.entitlements[IAPConfiguration.premiumEntitlementId]?.expirationDate {
            IAPStorage.saveSubscriptionExpiryDate(expirationDate)
            IAPNotificationManager.shared.scheduleExpirationReminder(for: expirationDate)
        }
    }
    
    @MainActor
    private func updateOfferings(_ newOfferings: Offerings) {
        offerings = newOfferings
        if let packages = newOfferings.current?.availablePackages {
            updateProducts(packages)
        }
    }
    
    @MainActor
    private func updateProducts(_ packages: [Package]) {
        products = packages.map { package in
            IAPProduct(
                package: package,
                isPopular: package.identifier == IAPConfiguration.yearlySubscriptionId
            )
        }
    }
    
    @MainActor
    private func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        let oldStatus = subscriptionStatus
        
        if let entitlement = customerInfo.entitlements[IAPConfiguration.premiumEntitlementId] {
            if entitlement.isActive {
                subscriptionStatus = .active(expirationDate: entitlement.expirationDate)
                if let currentPackage = products.first(where: { $0.id == entitlement.productIdentifier }) {
                    currentSubscription = currentPackage
                }
                
                if case .notSubscribed = oldStatus {
                    NotificationCenter.default.post(
                        name: .subscriptionStatusChanged,
                        object: nil,
                        userInfo: ["isPremium": true]
                    )
                }
            } else {
                subscriptionStatus = .expired(lastExpirationDate: entitlement.expirationDate)
                
                if case .active = oldStatus {
                    NotificationCenter.default.post(
                        name: .subscriptionStatusChanged,
                        object: nil,
                        userInfo: ["isPremium": false]
                    )
                }
            }
        } else {
            subscriptionStatus = .notSubscribed
        }
    }
    
    @MainActor
    private func updateError(_ error: IAPError) {
        self.error = error
    }
    
    // MARK: - 公共接口
    
    /// 购买指定产品
    /// - Parameter product: 要购买的产品
    /// - Throws: IAPError 类型的错误
    func purchase(_ product: IAPProduct) async throws {
        do {
            await updatePurchaseState(.purchasing)
            let purchaseResult = try await Purchases.shared.purchase(package: product.package)
            await updatePurchaseState(.completed)
            
            IAPStorage.savePurchaseHistory(product.id)
            IAPStorage.saveLastPurchaseDate(Date())
            
            NotificationCenter.default.post(
                name: .subscriptionStatusChanged,
                object: nil,
                userInfo: ["isPremium": true]
            )
            
            await updateCustomerInfo(purchaseResult.customerInfo)
            
            trackPurchaseEvent(product)
        } catch {
            await updatePurchaseState(.failed)
            let iapError = handlePurchaseError(error)
            await updateError(iapError)
            throw iapError
        }
    }
    
    /// 恢复之前的购买
    /// - Throws: IAPError 类型的错误
    func restorePurchases() async throws {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateCustomerInfo(customerInfo)
        } catch {
            let iapError = handlePurchaseError(error)
            await updateError(iapError)
            throw iapError
        }
    }
    
    /// 获取指定标识符的产品包
    /// - Parameter identifier: 产品标识符
    /// - Returns: 对应的产品包，如果不存在则返回 nil
    func package(withIdentifier identifier: String) -> Package? {
        offerings?.current?.package(identifier: identifier)
    }
    
    #if os(macOS)
    /// 记录由应用完成的购买（仅 macOS）
    /// - Parameter result: StoreKit 购买结果
    /// - Throws: RevenueCat 相关错误
    func recordPurchase(_ result: StoreKit.Product.PurchaseResult) async throws {
        _ = try await Purchases.shared.recordPurchase(result)
    }
    #endif
    
    // MARK: - 属性访问器
    
    /// 用户是否拥有高级会员权限
    var isPremium: Bool {
        customerInfo?.entitlements[IAPConfiguration.premiumEntitlementId]?.isActive == true
    }
    
    /// 订阅是否即将到期（30天内）
    var isSubscriptionExpiring: Bool {
        guard let expirationDate = customerInfo?.entitlements[IAPConfiguration.premiumEntitlementId]?.expirationDate else {
            return false
        }
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        return expirationDate < thirtyDaysFromNow
    }
    
    private func trackPurchaseEvent(_ product: IAPProduct) {
        #if DEBUG
        print("Purchase tracked: \(product.id), price: \(product.price), period: \(product.period)")
        #endif
        
        // TODO: 实现实际的分析追踪
        // Analytics.track("subscription_purchased", properties: [
        //     "product_id": product.id,
        //     "price": product.price,
        //     "period": product.period
        // ])
    }
    
    private func handlePurchaseError(_ error: Error) -> IAPError {
        if let revenueCatError = error as? RevenueCat.ErrorCode {
            switch revenueCatError {
            case .networkError:
                return .networkError
            case .purchaseCancelledError:
                return .userCancelled
            default:
                return .purchaseFailed
            }
        }
        return .purchaseFailed
    }
    
    @MainActor
    private func updatePurchaseState(_ state: PurchaseState) {
        purchaseState = state
    }
}

// MARK: - Purchase State
enum PurchaseState {
    case idle
    case purchasing
    case completed
    case failed
}

// MARK: - Subscription Status
enum SubscriptionStatus: Equatable {
    case loading
    case notSubscribed
    case active(expirationDate: Date?)
    case expired(lastExpirationDate: Date?)
    
    var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

// MARK: - PurchasesDelegate
extension IAPService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateCustomerInfo(customerInfo)
        }
    }
    
    func purchases(
        _ purchases: Purchases,
        readyForPromotedProduct product: StoreProduct,
        purchase: @escaping () -> Void
    ) {
        #if os(iOS)
        purchase()
        #else
        print("Promoted products not supported on macOS")
        #endif
    }
} 
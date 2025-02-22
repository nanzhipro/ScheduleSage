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
import OSLog

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
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "IAPService")
    
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
    
    /// 是否为高级会员
    @Published private(set) var isPremium = false
    
    /// 产品加载状态
    @Published private(set) var offeringsLoadingState: LoadingState = .idle
    
    /// 用于存储取消令牌的集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    private override init() {
        super.init()
    }
    
    /// 初始化 IAP 服务
    /// 配置 SDK、设置监听并获取产品信息
    func initialize() async {
        logger.info("[IAP] Starting initialization at \(Date())")
        
        configureSDK()
        setupSubscriptionMonitoring()
        
        logger.debug("[IAP] Fetching offerings and restoring purchases...")
        await fetchOfferings()
        
        do {
            let restored = try await restorePurchases()
            logger.notice("[IAP] Restore completed - Premium status: \(restored)")
        } catch {
            logger.error("[IAP] Restore failed: \(error.localizedDescription)")
        }
        
        logger.notice("[IAP] Initialization completed. Premium: \(self.isPremium), Status: \(self.subscriptionStatus.description)")
    }
    
    // MARK: - 配置方法
    
    /// 配置 RevenueCat SDK
    private func configureSDK() {
        logger.info("[IAP] Configuring RevenueCat SDK with API key: \(String(IAPConfiguration.apiKey.prefix(6)))...")
        Purchases.configure(
            with: Configuration.builder(withAPIKey: IAPConfiguration.apiKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
        logger.debug("[IAP] SDK configuration completed")
    }
    
    /// 设置订阅状态监控
    private func setupSubscriptionMonitoring() {
        logger.info("[IAP] Setting up subscription monitoring")
        Task {
            logger.debug("[IAP] Starting customer info stream monitoring")
            for await customerInfo in Purchases.shared.customerInfoStream {
                logger.debug("[IAP] Received customer info update: \(customerInfo.originalApplicationVersion ?? "unknown")")
                await updateCustomerInfo(customerInfo)
            }
        }
        Purchases.shared.delegate = self
    }
    
    // MARK: - 数据管理
    
    /// 获取可用的产品组合
    private func fetchOfferings() async {
        logger.info("[IAP] Starting offerings fetch")
        await updateOfferingsLoadingState(.loading)
        
        do {
            let offerings = try await Purchases.shared.offerings()
            logger.debug("[IAP] Available offerings: \(offerings.all.keys.joined(separator: ", "))")
            logger.debug("[IAP] Current offering packages: \(offerings.current?.availablePackages.map { $0.identifier } ?? [])")
            
            await updateOfferings(offerings)
            await updateOfferingsLoadingState(.success)
            logger.notice("[IAP] Offerings fetch completed successfully")
        } catch {
            logger.error("[IAP] Offerings fetch failed: \(error.localizedDescription)")
            await updateError(.productNotFound)
            await updateOfferingsLoadingState(.failed)
        }
    }
    
    /// 更新用户订阅信息
    /// - Parameter info: 新的用户信息
    @MainActor
    private func updateCustomerInfo(_ info: CustomerInfo) {
        logger.debug("[IAP] Updating customer info - Original App Version: \(info.originalApplicationVersion ?? "unknown")")
        customerInfo = info
        
        if let entitlement = info.entitlements[IAPConfiguration.premiumEntitlementId] {
            let isActive = entitlement.isActive
            let expirationDate = entitlement.expirationDate
            logger.debug("[IAP] Premium entitlement - Active: \(isActive), Expires: \(expirationDate?.description ?? "none")")
            
            if isActive {
                subscriptionStatus = .active(expirationDate: expirationDate)
                isPremium = true
                logger.notice("[IAP] Active subscription detected")
            } else {
                subscriptionStatus = .expired(lastExpirationDate: expirationDate)
                isPremium = false
                logger.notice("[IAP] Expired subscription detected")
            }
        } else {
            subscriptionStatus = .notSubscribed
            isPremium = false
            logger.debug("[IAP] No subscription found")
        }
        
        logger.info("[IAP] Customer info updated - Premium: \(self.isPremium), Status: \(self.subscriptionStatus.description)")
        NotificationCenter.default.post(
            name: .subscriptionStatusChanged,
            object: nil,
            userInfo: ["isPremium": isPremium, "subscriptionStatus": subscriptionStatus]
        )
    }
    
    @MainActor
    private func updateOfferings(_ newOfferings: Offerings) {
        offerings = newOfferings
        if let packages = newOfferings.current?.availablePackages {
            products = packages.map { package in
                IAPProduct(
                    package: package,
                    isPopular: package.identifier == IAPConfiguration.yearlySubscriptionId
                )
            }
        }
    }
    
    @MainActor
    private func updateError(_ error: IAPError) {
        self.error = error
    }
    
    @MainActor
    private func updateOfferingsLoadingState(_ state: LoadingState) {
        offeringsLoadingState = state
    }
    
    // MARK: - 公共接口
    
    /// 购买指定产品
    /// - Parameter product: 要购买的产品
    /// - Throws: IAPError 类型的错误
    func purchase(_ product: IAPProduct) async throws {
        logger.info("[IAP] Starting purchase for product: \(product.id) at \(Date())")
        await updatePurchaseState(.purchasing)
        
        do {
            logger.debug("[IAP] Attempting purchase with RevenueCat")
            let result = try await Purchases.shared.purchase(package: product.package)
            
            if result.userCancelled {
                logger.notice("[IAP] Purchase cancelled by user")
                await updatePurchaseState(.cancelled)
                throw IAPError.userCancelled
            }
            
            logger.debug("[IAP] Purchase completed, updating customer info")
            await updateCustomerInfo(result.customerInfo)
            
            if !isPremium {
                logger.error("[IAP] Purchase completed but premium status not activated")
                await updatePurchaseState(.failed)
                throw IAPError.purchaseFailed
            }
            
            logger.notice("[IAP] Purchase completed successfully - Product: \(product.id)")
            await updatePurchaseState(.completed)
        } catch {
            let iapError = handlePurchaseError(error)
            logger.error("[IAP] Purchase failed: \(iapError.localizedDescription)")
            await updateError(iapError)
            await updatePurchaseState(.failed)
            throw iapError
        }
    }
    
    /// 恢复之前的购买
    /// - Returns: 恢复结果，包含是否有活跃订阅
    /// - Throws: IAPError 类型的错误（仅在网络错误等情况下抛出）
    func restorePurchases() async throws -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateCustomerInfo(customerInfo)
            return isPremium
        } catch {
            await updateError(.restoreFailed)
            throw error
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
    
    /// 订阅是否即将到期（30天内）
    var isSubscriptionExpiring: Bool {
        guard let expirationDate = customerInfo?.entitlements[IAPConfiguration.premiumEntitlementId]?.expirationDate else {
            return false
        }
        return expirationDate < Date().addingTimeInterval(30 * 24 * 60 * 60)
    }
    
    private func handlePurchaseError(_ error: Error) -> IAPError {
        if let iapError = error as? IAPError { return iapError }
        if let rcError = error as? RevenueCat.ErrorCode {
            switch rcError {
            case .networkError: return .networkError
            case .purchaseCancelledError: return .userCancelled
            case .paymentPendingError: return .paymentPending
            default: return .purchaseFailed
            }
        }
        return .purchaseFailed
    }
    
    @MainActor
    private func updatePurchaseState(_ state: PurchaseState) {
        purchaseState = state
        NotificationCenter.default.post(
            name: .purchaseStatusChanged,
            object: nil,
            userInfo: ["message": state.localizedMessage]
        )
    }
    
    /// 清除当前错误
    @MainActor
    func clearError() {
        error = nil
    }
}

// MARK: - Purchase State
enum PurchaseState {
    case idle
    case purchasing
    case completed
    case cancelled
    case pending
    case failed
    
    var description: String {
        switch self {
        case .idle: return "idle"
        case .purchasing: return "purchasing"
        case .completed: return "completed"
        case .cancelled: return "cancelled"
        case .pending: return "pending"
        case .failed: return "failed"
        }
    }
    
    var localizedMessage: String {
        switch self {
        case .purchasing: return NSLocalizedString("paywall.purchase.processing", comment: "")
        case .completed: return NSLocalizedString("paywall.purchase.success", comment: "")
        case .cancelled: return NSLocalizedString("paywall.purchase.cancelled", comment: "")
        case .failed: return NSLocalizedString("paywall.purchase.failed", comment: "")
        default: return ""
        }
    }
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
    
    // 添加字符串表示
    var description: String {
        switch self {
        case .loading:
            return "loading"
        case .notSubscribed:
            return "not_subscribed"
        case .active(let expirationDate):
            return "active(expires: \(expirationDate?.description ?? "none"))"
        case .expired(let lastExpirationDate):
            return "expired(last: \(lastExpirationDate?.description ?? "none"))"
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    static let purchaseStatusChanged = Notification.Name("purchaseStatusChanged")
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
        purchase: @escaping StartPurchaseBlock
    ) {
        Task {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    purchase { [weak self] transaction, customerInfo, error, userCancelled in
                        guard let self = self else {
                            continuation.resume(throwing: IAPError.purchaseFailed)
                            return
                        }
                        
                        if let error = error {
                            self.logger.error("[IAP] Promoted purchase callback error: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        if userCancelled {
                            self.logger.notice("[IAP] User cancelled promoted purchase")
                            continuation.resume(throwing: IAPError.userCancelled)
                            return
                        }
                        
                        if let customerInfo = customerInfo {
                            self.logger.notice("[IAP] Promoted purchase callback successful")
                            Task { @MainActor in
                                self.updateCustomerInfo(customerInfo)
                            }
                            continuation.resume(returning: ())
                        } else {
                            continuation.resume(throwing: IAPError.purchaseFailed)
                        }
                    }
                }
                logger.notice("[IAP] Promoted purchase successful")
            } catch {
                logger.error("[IAP] Promoted purchase failed: \(error.localizedDescription)")
                await updateError(.purchaseFailed)
            }
        }
    }
}

// MARK: - Loading State
enum LoadingState {
    case idle
    case loading
    case success
    case failed
} 

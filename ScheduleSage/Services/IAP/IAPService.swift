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
    
    private let logger: Logger
    
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
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "IAPService")
        super.init()
        logger.info("[IAP] Initializing IAP service")
    }
    
    /// 初始化 IAP 服务
    /// 配置 SDK、设置监听并获取产品信息
    func initialize() async {
        logger.info("[IAP] Starting IAP service initialization")
        
        // 配置 SDK 和设置监听
        configureSDK()
        setupSubscriptionMonitoring()
        
        // 获取产品信息
        await fetchOfferings()
        
        // 尝试恢复已购买的内容
        do {
            _ = try await restorePurchases() // 使用 _ 忽略返回值
            logger.notice("[IAP] Successfully restored previous purchases")
        } catch {
            logger.error("[IAP] Failed to restore purchases: \(error.localizedDescription)")
        }
        
        logger.notice("[IAP] IAP service initialization completed")
    }
    
    // MARK: - 配置方法
    
    /// 配置 RevenueCat SDK
    private func configureSDK() {
        logger.info("[IAP] Configuring RevenueCat with API key: \(IAPConfiguration.apiKey)")
        Purchases.logLevel = .debug
        Purchases.configure(
            with: Configuration.builder(withAPIKey: IAPConfiguration.apiKey)
                .with(storeKitVersion: .storeKit2)
                .build()
        )
        
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
        logger.info("[IAP] Setting up subscription monitoring")
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                logger.debug("[IAP] Received customer info update")
                await updateCustomerInfo(customerInfo)
            }
        }
        Purchases.shared.delegate = self
    }
    
    // MARK: - 数据管理
    
    /// 获取可用的产品组合
    private func fetchOfferings() async {
        await updateOfferingsLoadingState(.loading)
        logger.info("[IAP] Fetching available offerings")
        
        do {
            let offerings = try await Purchases.shared.offerings()
            logger.debug("[IAP] Received offerings: \(offerings.all.keys.joined(separator: ", "))")
            await updateOfferings(offerings)
            await updateOfferingsLoadingState(.success)
        } catch {
            logger.error("[IAP] Failed to fetch offerings: \(error.localizedDescription)")
            await updateError(.productNotFound)
            await updateOfferingsLoadingState(.failed)
        }
    }
    
    /// 更新用户订阅信息
    /// - Parameter info: 新的用户信息
    @MainActor
    private func updateCustomerInfo(_ info: CustomerInfo) {
        logger.info("[IAP] Updating customer info")
        self.customerInfo = info
        
        // 检查订阅状态
        if let entitlement = info.entitlements[IAPConfiguration.premiumEntitlementId] {
            if entitlement.isActive {
                subscriptionStatus = .active(expirationDate: entitlement.expirationDate)
                isPremium = true
                logger.notice("[IAP] Active subscription found, expires: \(String(describing: entitlement.expirationDate))")
            } else {
                subscriptionStatus = .expired(lastExpirationDate: entitlement.expirationDate)
                isPremium = false
                logger.notice("[IAP] Expired subscription found, last expiry: \(String(describing: entitlement.expirationDate))")
            }
        } else {
            subscriptionStatus = .notSubscribed
            isPremium = false
            logger.notice("[IAP] No subscription found")
        }
        
        // 发送订阅状态变更通知
        NotificationCenter.default.post(
            name: .subscriptionStatusChanged,
            object: nil,
            userInfo: [
                "isPremium": self.isPremium,
                "subscriptionStatus": self.subscriptionStatus
            ]
        )
        logger.debug("[IAP] Posted subscription status change - isPremium: \(self.isPremium), status: \(self.subscriptionStatus.description)")
    }
    
    @MainActor
    private func updateOfferings(_ newOfferings: Offerings) {
        logger.debug("[IAP] Updating offerings")
        offerings = newOfferings
        if let packages = newOfferings.current?.availablePackages {
            logger.debug("[IAP] Available packages: \(packages.map { $0.identifier }.joined(separator: ", "))")
            updateProducts(packages)
        }
    }
    
    @MainActor
    private func updateProducts(_ packages: [Package]) {
        logger.debug("[IAP] Updating product list")
        products = packages.map { package in
            IAPProduct(
                package: package,
                isPopular: package.identifier == IAPConfiguration.yearlySubscriptionId
            )
        }
    }
    
    @MainActor
    private func updateError(_ error: IAPError) {
        logger.error("[IAP] Purchase error: \(error.localizedDescription)")
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
        await updatePurchaseState(.purchasing)
        logger.info("[IAP] Starting purchase for product: \(product.id)")
        
        do {
            // 尝试购买
            let result = try await Purchases.shared.purchase(package: product.package)
            
            // 检查是否是用户取消
            if result.userCancelled {
                logger.notice("[IAP] Purchase cancelled by user")
                await updatePurchaseState(.cancelled)
                throw IAPError.userCancelled
            }
            
            // 更新用户信息
            await updateCustomerInfo(result.customerInfo)
            
            // 验证订阅是否激活
            if !isPremium {
                logger.error("[IAP] Purchase verification failed")
                await updateError(.purchaseFailed)
                await updatePurchaseState(.failed)
                throw IAPError.purchaseFailed
            }
            
            logger.notice("[IAP] Purchase completed successfully")
            await updatePurchaseState(.completed)
            trackPurchaseEvent(product)
        } catch {
            // 处理其他错误
            if let rcError = error as? RevenueCat.ErrorCode {
                switch rcError {
                case .purchaseCancelledError:
                    logger.notice("[IAP] Purchase cancelled by user")
                    await updatePurchaseState(.cancelled)
                    throw IAPError.userCancelled
                case .paymentPendingError:
                    logger.notice("[IAP] Payment is pending")
                    await updatePurchaseState(.pending)
                    throw IAPError.paymentPending
                case .networkError:
                    logger.error("[IAP] Purchase failed due to network error")
                    await updateError(.networkError)
                    await updatePurchaseState(.failed)
                    throw IAPError.networkError
                default:
                    logger.error("[IAP] Purchase failed: \(rcError.localizedDescription)")
                    await updateError(.purchaseFailed)
                    await updatePurchaseState(.failed)
                    throw IAPError.purchaseFailed
                }
            }
            
            // 处理未知错误
            logger.error("[IAP] Unknown purchase error: \(error.localizedDescription)")
            await updateError(.purchaseFailed)
            await updatePurchaseState(.failed)
            throw IAPError.purchaseFailed
        }
    }
    
    /// 恢复之前的购买
    /// - Returns: 恢复结果，包含是否有活跃订阅
    /// - Throws: IAPError 类型的错误（仅在网络错误等情况下抛出）
    func restorePurchases() async throws -> Bool {
        logger.info("[IAP] Attempting to restore purchases")
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateCustomerInfo(customerInfo)
            
            // 检查是否有活跃订阅，但不视为错误
            if !isPremium {
                logger.notice("[IAP] Restore completed but no active subscription found")
                return false
            }
            
            logger.notice("[IAP] Purchases restored successfully")
            return true
        } catch {
            logger.error("[IAP] Restore failed: \(error.localizedDescription)")
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
        // 记录详细错误信息
        logger.error("[IAP] Raw purchase error: \(error)")
        
        // 如果已经是 IAPError，直接返回
        if let iapError = error as? IAPError {
            return iapError
        }
        
        // 处理 RevenueCat 错误
        if let rcError = error as? RevenueCat.ErrorCode {
            switch rcError {
            case .networkError:
                logger.error("[IAP] Network error during purchase")
                return .networkError
            case .purchaseCancelledError:
                logger.notice("[IAP] User cancelled purchase")
                return .userCancelled
            case .paymentPendingError:
                logger.notice("[IAP] Payment is pending")
                return .paymentPending
            case .invalidCredentialsError:
                logger.error("[IAP] Invalid credentials for purchase")
                return .purchaseFailed
            case .configurationError:
                logger.error("[IAP] Configuration error: \(rcError.localizedDescription)")
                return .configurationError
            case .storeProblemError:
                logger.error("[IAP] Store problem: \(rcError.localizedDescription)")
                return .storeProblem
            default:
                logger.error("[IAP] Unhandled RevenueCat error: \(rcError.localizedDescription)")
                return .purchaseFailed
            }
        }
        
        // 处理 StoreKit 错误
        if let storeError = error as? StoreKit.SKError {
            switch storeError.code {
            case .storeProductNotAvailable:
                logger.error("[IAP] StoreKit product not available")
                return .storeNotAvailable
            case .cloudServiceNetworkConnectionFailed:
                logger.error("[IAP] StoreKit network error")
                return .networkError
            case .paymentCancelled:
                logger.notice("[IAP] User cancelled StoreKit payment")
                return .userCancelled
            case .paymentInvalid:
                logger.error("[IAP] StoreKit invalid payment")
                return .purchaseFailed
            case .clientInvalid:
                logger.error("[IAP] StoreKit client invalid")
                return .configurationError
            default:
                logger.error("[IAP] Unhandled StoreKit error: \(storeError.localizedDescription)")
                return .purchaseFailed
            }
        }
        
        // 处理 AMSErrorDomain 错误
        let nsError = error as NSError
        if nsError.domain == "AMSErrorDomain" {
            switch nsError.code {
            case 301:
                logger.error("[IAP] App Store authorization error (403)")
                return .storeAuthError
            default:
                logger.error("[IAP] App Store error: \(nsError.localizedDescription)")
                return .storeProblem
            }
        }
        
        logger.error("[IAP] Unknown error: \(error.localizedDescription)")
        return .purchaseFailed
    }
    
    @MainActor
    private func updatePurchaseState(_ state: PurchaseState) {
        purchaseState = state
        
        // 根据状态发送通知并显示相应提示
        switch state {
        case .purchasing:
            NotificationCenter.default.post(
                name: .purchaseStatusChanged,
                object: nil,
                userInfo: ["message": NSLocalizedString("paywall.purchase.processing", comment: "")]
            )
        case .completed:
            NotificationCenter.default.post(
                name: .purchaseStatusChanged,
                object: nil,
                userInfo: ["message": NSLocalizedString("paywall.purchase.success", comment: "")]
            )
        case .cancelled:
            NotificationCenter.default.post(
                name: .purchaseStatusChanged,
                object: nil,
                userInfo: ["message": NSLocalizedString("paywall.purchase.cancelled", comment: "")]
            )
        case .failed:
            NotificationCenter.default.post(
                name: .purchaseStatusChanged,
                object: nil,
                userInfo: ["message": NSLocalizedString("paywall.purchase.failed", comment: "")]
            )
        default:
            break
        }
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
        logger.debug("[IAP] Received delegate update for customer info")
        Task { @MainActor in
            updateCustomerInfo(customerInfo)
        }
    }
    
    func purchases(
        _ purchases: Purchases,
        readyForPromotedProduct product: StoreProduct,
        purchase: @escaping StartPurchaseBlock
    ) {
        logger.debug("[IAP] Ready for promoted product: \(product.productIdentifier)")
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

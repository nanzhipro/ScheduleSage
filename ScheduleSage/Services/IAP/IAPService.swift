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
@MainActor
class IAPService: NSObject, ObservableObject {
    /// 共享实例
    static let shared = IAPService()
    
    private let logger = LoggerService.makeCompatible(category: "IAPService")
    private let configService = ConfigService()
    private var appConfig: AppConfig = AppConfig(revenuecatApiKey: "", enablePremiumFeaturesWhenUnsubscribed: false)
    
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
    
    /// 初始化状态
    @Published private(set) var isInitialized = false
    
    @Published private(set) var isConfigured: Bool = false
    
    private let configuredSubject = PassthroughSubject<Void, Never>()
    
    // 新增初始化完成的 Subject
    private let initializationCompletedSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - 初始化
    private override init() {
        super.init()
        logger.info("[IAP] Service instance created")
        
        // 初始化时自动启动配置过程
        Task {
            try? await configureSDK()
        }
    }
    
    /// 配置 RevenueCat SDK
    private func configureSDK() async throws {
        // 如果已经配置过，直接返回
        guard !isConfigured else {
            logger.info("[IAP] SDK already configured, skipping configuration")
            return
        }
        
        do {
            // 首先获取应用配置
            logger.info("[IAP] Fetching app configuration...")
            let appConfig = try await configService.fetchConfig()
            self.appConfig = appConfig

            logger.info("[IAP] Configuring RevenueCat SDK with fetched API key...")
            
            // 使用获取到的 API key 配置 RevenueCat
            Purchases.configure(
                with: Configuration.Builder(withAPIKey: appConfig.revenuecatApiKey)
                    .with(storeKitVersion: .storeKit2)
                    .with(networkTimeout: 30)
                    .with(storeKit1Timeout: 30)
                    .build()
            )
            
            isConfigured = true
            configuredSubject.send()
            logger.info("[IAP] SDK configuration completed")
            
            // 配置完成后启动初始化过程
            try await initializeIAPService()
        } catch {
            logger.error("[IAP] Failed to configure SDK: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 初始化 RevenueCat SDK 和相关功能
    func initializeIAPService() async throws {
        // 如果已经初始化，直接返回
        guard !isInitialized else {
            logger.info("[IAP] Service already initialized")
            return
        }
        
        // 设置监听和初始化其他功能
        setupObservers()
        
        do {
            // 初始化客户信息
            try await initializeCustomerInfo()
            
            // 获取当前订阅状态
            let hasActiveSubscription = isPremium
            logger.info("[IAP] Service initialization completed - Premium status: \(hasActiveSubscription)")
            
            await MainActor.run {
                isInitialized = true
                // 通知初始化完成
                initializationCompletedSubject.send()
            }
        } catch {
            logger.error("[IAP] Service initialization failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 等待初始化完成
    /// 可以在需要确保 IAP 服务已初始化的地方调用此方法
    func waitForInitialization() async {
        if isInitialized {
            return
        }
        
        return await withCheckedContinuation { continuation in
            let cancellable = initializationCompletedSubject
                .first()
                .sink { _ in
                    continuation.resume()
                }
            
            cancellables.insert(cancellable)
        }
    }
    
    /// 清理 RevenueCat 状态和观察者
    func cleanupState() async {
        // 重置状态
        customerInfo = nil
        offerings = nil
        products = []
        currentSubscription = nil
        purchaseState = .idle
        error = nil
        subscriptionStatus = .loading
        isPremium = false
        offeringsLoadingState = .idle
        isInitialized = false
        
        // 清理观察者
        cancellables.removeAll()
    }
    
    /// 使用用户 ID 登录 RevenueCat
    /// 因为 Apple 会处理跨设备订阅，所以这里暂时不需要 login 了
    /// - Parameter userId: Apple ID 用户标识
    func login(userId: String) async throws {
        guard !isInitialized else { return }
        
        do {
            let result = try await Purchases.shared.logIn(userId)
            updateCustomerInfo(result.customerInfo)
            try await initializeIAPService()
            isInitialized = true
        } catch {
            throw error
        }
    }

    /// 登出并清理状态
    func logout() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            updateCustomerInfo(customerInfo)
            await cleanupState()
        } catch {
            logger.error("[IAP] Error during logout: \(error.localizedDescription)")
        }
    }
    
    /// 设置订阅状态监控
    private func setupObservers() {
        setupSubscriptionMonitoring()
        setupLifecycleObservers()
    }
    
    private func setupSubscriptionMonitoring() {
        logger.info("[IAP] Setting up subscription monitoring")
        Task {
            logger.info("[IAP] Starting customer info stream monitoring")
            for await customerInfo in Purchases.shared.customerInfoStream {
                logger.info("[IAP] Received customer info update: \(customerInfo.originalApplicationVersion ?? "unknown")")
                updateCustomerInfo(customerInfo)
            }
        }
        Purchases.shared.delegate = self
    }
    
    // MARK: - 生命周期观察
    private func setupLifecycleObservers() {
        #if os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif
    }
    
    @objc private func applicationDidBecomeActive() {
        Task {
            do {
                try await refreshCustomerInfo()
                logger.info("[IAP] Customer info refreshed after app became active")
            } catch {
                logger.error("[IAP] Failed to refresh customer info on app active: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 数据管理
    
    /// 获取可用的产品组合
    private func fetchOfferings() async {
        logger.info("[IAP] Starting offerings fetch")
        updateOfferingsLoadingState(.loading)
        
        do {
            let offerings = try await Purchases.shared.offerings()
            logger.info("[IAP] Available offerings: \(offerings.all.keys.joined(separator: ", "))")
            logger.info("[IAP] Current offering packages: \(offerings.current?.availablePackages.map { $0.identifier } ?? [])")
            
            updateOfferings(offerings)
            updateOfferingsLoadingState(.success)
            logger.notice("[IAP] Offerings fetch completed successfully")
        } catch {
            logger.error("[IAP] Offerings fetch failed: \(error.localizedDescription)")
            updateError(.productNotFound)
            updateOfferingsLoadingState(.failed)
        }
    }
    
    /// 更新用户订阅信息
    /// - Parameter info: 新的用户信息
    private func updateCustomerInfo(_ info: CustomerInfo) {
        Task { @MainActor in
            logger.info("[IAP] Updating customer info - Original App Version: \(info.originalApplicationVersion ?? "unknown")")
            customerInfo = info
            
            if let entitlement = info.entitlements[IAPConfiguration.premiumEntitlementId] {
                let isActive = entitlement.isActive
                let expirationDate = entitlement.expirationDate
                logger.info("[IAP] Premium entitlement - Active: \(isActive), Expires: \(expirationDate?.description ?? "none")")
                
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
                logger.info("[IAP] No subscription found")
            }
            
            logger.info("[IAP] Customer info updated - Premium: \(self.isPremium), Status: \(self.subscriptionStatus.description)")
            NotificationCenter.default.post(
                name: .subscriptionStatusChanged,
                object: nil,
                userInfo: ["isPremium": isPremium, "subscriptionStatus": subscriptionStatus]
            )
        }
    }
    
    private func updateOfferings(_ newOfferings: Offerings) {
        Task { @MainActor in
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
    }
    
    private func updateError(_ error: IAPError) {
        Task { @MainActor in
            self.error = error
        }
    }
    
    private func updateOfferingsLoadingState(_ state: LoadingState) {
        Task { @MainActor in
            offeringsLoadingState = state
        }
    }
    
    // MARK: - 公共接口
    
    /// 购买指定产品
    /// - Parameter product: 要购买的产品
    /// - Throws: IAPError 类型的错误
    func purchase(_ product: IAPProduct) async throws {
        logger.info("[IAP] Starting purchase for product: \(product.id) at \(Date())")
        updatePurchaseState(.purchasing)
        
        do {
            logger.info("[IAP] Attempting purchase with RevenueCat")
            let result = try await Purchases.shared.purchase(package: product.package)
            
            if result.userCancelled {
                logger.notice("[IAP] Purchase cancelled by user")
                updatePurchaseState(.cancelled)
                throw IAPError.userCancelled
            }
            
            logger.info("[IAP] Purchase completed, updating customer info")
            updateCustomerInfo(result.customerInfo)
            
            try await refreshCustomerInfo()
            
            if !isPremium {
                logger.error("[IAP] Purchase completed but premium status not activated")
                updatePurchaseState(.failed)
                throw IAPError.purchaseFailed
            }
            
            logger.notice("[IAP] Purchase completed successfully - Product: \(product.id)")
            updatePurchaseState(.completed)
        } catch {
            handlePurchaseError(error)
        }
    }
    
    /// 恢复之前的购买
    /// - Returns: 恢复结果，包含是否有活跃订阅
    /// - Throws: IAPError 类型的错误（仅在网络错误等情况下抛出）
    /// restorePurchases 方法不应通过编程触发，因为这可能会导致操作系统级别的登录提示出现，应该仅在某些用户交互（例如，点击"恢复"按钮）时调用。
    /// 
    /// 注意：虽然 syncPurchases 不会触发系统级别的登录提示，但它通常用于迁移订阅，并且存在转移或别名化匿名用户的风险。
    /// 对于常规的购买状态检查，请使用 Purchases.shared.customerInfo() 方法。
    func restorePurchases() async throws -> Bool {
        logger.info("[IAP] Starting purchase restoration")
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            logger.info("[IAP] Purchase restoration completed, updating customer info")
            updateCustomerInfo(customerInfo)
            
            let hasActiveSubscription = isPremium
            logger.info("[IAP] Purchase restoration result - Has active subscription: \(hasActiveSubscription)")
            return hasActiveSubscription
        } catch {
            logger.error("[IAP] Purchase restoration failed: \(error.localizedDescription)")
            updateError(.restoreFailed)
            throw error
        }
    }
    
    /// 同步购买记录
    /// - Returns: 同步结果，包含是否有活跃订阅
    /// - Throws: IAPError 类型的错误
    /// 此方法适用于编程方式同步购买记录，不会触发系统级别的登录提示
    /// 
    /// 警告：
    /// 1. syncPurchases 通常用于迁移订阅，不应在常规初始化流程中使用
    /// 2. 由于此方法模拟恢复购买，存在转移或别名化匿名用户的风险
    /// 3. 仅在特定场景下使用此方法，如用户账户迁移或订阅转移
    func syncPurchases() async throws -> Bool {
        logger.info("[IAP] Starting purchase synchronization")
        do {
            let customerInfo = try await Purchases.shared.syncPurchases()
            logger.info("[IAP] Purchase synchronization completed, updating customer info")
            updateCustomerInfo(customerInfo)
            
            let hasActiveSubscription = isPremium
            logger.info("[IAP] Purchase synchronization result - Has active subscription: \(hasActiveSubscription)")
            return hasActiveSubscription
        } catch {
            logger.error("[IAP] Purchase synchronization failed: \(error.localizedDescription)")
            updateError(.syncFailed)
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
    
    /// 判断用户当前的订阅类型
    /// - Returns: 当前订阅的产品标识符，如果没有订阅则返回nil
    func getCurrentSubscriptionIdentifier() -> String? {
        guard isPremium,
              let entitlement = customerInfo?.entitlements[IAPConfiguration.premiumEntitlementId],
              entitlement.isActive else {
            return nil
        }
        
        // 从产品ID中提取订阅类型
        return entitlement.productIdentifier
    }
    
    /// 检查用户是否订阅了特定类型的订阅
    /// - Parameter identifier: 产品标识符或部分标识符（如"monthly"或"yearly"）
    /// - Returns: 是否订阅了该类型
    func hasSubscription(containing identifier: String) -> Bool {
        guard let currentId = getCurrentSubscriptionIdentifier() else {
            return false
        }
        
        return currentId.lowercased().contains(identifier.lowercased())
    }
    
    private func handlePurchaseError(_ error: Error) {
        Task { @MainActor in
            let iapError = (error as? IAPError) ?? .purchaseFailed
            self.error = iapError
            purchaseState = .failed
        }
    }
    
    private func updatePurchaseState(_ state: PurchaseState) {
        Task { @MainActor in
            purchaseState = state
            NotificationCenter.default.post(
                name: .purchaseStatusChanged,
                object: nil,
                userInfo: ["message": state.localizedMessage]
            )
        }
    }
    
    /// 清除当前错误
    func clearError() {
        error = nil
    }
    
    // MARK: - 新增便捷方法
    
    /// 检查用户是否有任何活跃的订阅
    /// 这是一个便捷方法，用于快速检查用户是否有任何活跃的订阅
    var hasActiveSubscription: Bool {
        customerInfo?.entitlements.active.isEmpty == false
    }
    
    /// 主动刷新客户信息
    /// 在访问高级内容前调用此方法以确保状态最新
    func refreshCustomerInfo() async throws {
        logger.info("[IAP] Manually refreshing customer info")
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateCustomerInfo(customerInfo)
        } catch {
            logger.error("[IAP] Failed to refresh customer info: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 检查高级功能访问权限
    /// 在访问高级功能前调用此方法
    func checkPremiumAccess() async throws -> Bool {
        // 确保服务已初始化
        if !isInitialized {
            await waitForInitialization()
        }
        
        // 如果尚未配置完成，等待配置
        if !isConfigured {
            try await waitForConfiguration()
        }
        
        let isPremiumSubscribed = try await checkSubscriptionStatus()
        let canAccess = isPremiumSubscribed || appConfig.enablePremiumFeaturesWhenUnsubscribed
        logger.info("[IAP] Premium access check - Subscribed: \(isPremiumSubscribed), Override enabled: \(appConfig.enablePremiumFeaturesWhenUnsubscribed), Can access: \(canAccess)")
        return canAccess
    }
    
    /// 等待配置完成
    private func waitForConfiguration() async throws {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let cancellable = configuredSubject
                .first()
                .sink { [weak self] _ in
                    if self == nil {
                        continuation.resume(throwing: IAPError.configurationFailed)
                        return
                    }
                    continuation.resume(returning: ())
                }
            
            // 将 cancellable 存储到实例变量中，避免内存泄漏
            cancellables.insert(cancellable)
        }
    }
    
    /// 检查订阅状态
    func checkSubscriptionStatus() async throws -> Bool {
        // 确保服务已初始化
        if !isInitialized {
            await waitForInitialization()
        }
        
        // 如果尚未配置完成，等待配置
        if !isConfigured {
            try await waitForConfiguration()
        }
        
        let customerInfo = try await Purchases.shared.customerInfo()
        let isPremiumSubscribed = customerInfo.entitlements[IAPConfiguration.premiumEntitlementId]?.isActive == true
        logger.info("[IAP] Check subscription status - Subscribed: \(isPremiumSubscribed)")
        
        // 在 MainActor 上更新 isPremium 属性
        await MainActor.run {
            self.isPremium = isPremiumSubscribed
        }
        
        return isPremiumSubscribed
    }
    
    /// 初始化客户信息
    /// 通过调用 refreshCustomerInfo 获取最新的客户订阅状态
    /// 这是初始化过程中的关键步骤，确保应用启动时能获取正确的订阅状态
    private func initializeCustomerInfo() async throws {
        try await refreshCustomerInfo()
    }
    
    // MARK: - Public Methods
    
    /// 刷新所有订阅相关数据
    /// 包括产品列表和用户订阅状态
    func refreshSubscriptionData() async throws {
        // 确保服务已初始化
        if !isInitialized {
            await waitForInitialization()
        }
        
        await fetchOfferings()
        try await refreshCustomerInfo()
    }
    
    /// 延迟加载订阅产品信息
    /// 仅在需要时调用此方法，例如打开付费墙时
    func lazyLoadOfferings() async {
        // 确保服务已初始化
        if !isInitialized {
            await waitForInitialization()
        }
        
        // 如果已经有数据，就不需要再次加载
        if offerings != nil && !products.isEmpty {
            return
        }
        
        await fetchOfferings()
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
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateCustomerInfo(customerInfo)
        }
    }
    
    nonisolated func purchases(
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
                await logger.notice("[IAP] Promoted purchase successful")
            } catch {
                await logger.error("[IAP] Promoted purchase failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self.updateError(.purchaseFailed)
                }
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

// 在 AppDelegate 或 App 的入口处调用初始化
extension IAPService {
    /// 应用启动时调用此方法完成初始化
    static func bootstrap() async {
        // 服务在初始化时已经自动开始初始化过程
        // 这里只需等待初始化完成
        await shared.waitForInitialization()
    }
} 

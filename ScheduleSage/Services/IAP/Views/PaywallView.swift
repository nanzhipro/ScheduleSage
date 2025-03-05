//
//  PaywallView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import SwiftUI
import RevenueCat

/// 付费墙视图组件
/// 展示订阅选项和功能介绍
struct PaywallView: View {
    // MARK: - Properties
    let onPurchaseCompleted: () -> Void
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var iapService: IAPService
    
    // MARK: - State
    @State private var selectedPackage: Package?
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(spacing: DesignSystem.Spacing.medium) {
                closeButton
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.small) {
                        headerSection
                            .padding(.bottom, DesignSystem.Spacing.small)
                        
                        subscriptionOptionsSection
                            .padding(.bottom, DesignSystem.Spacing.small)
                        
                        purchaseSection
                        
                        subscriptionTermsText
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                }
            }
        }
        .frame(
            width: PaywallDimensions.containerWidth,
            height: PaywallDimensions.containerHeight
        )
        .background(DesignSystem.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .toast(isPresented: $showToast, type: .success, message: toastMessage)
        .task {
            await refreshSubscriptionData()
        }
        .onChange(of: iapService.offeringsLoadingState) { newState in
            if newState == .success {
                selectMonthlySubscription()
            }
        }
        .onAppear {
            // 如果数据已经加载完成，直接选择月度订阅
            if iapService.offeringsLoadingState == .success {
                selectMonthlySubscription()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var closeButton: some View {
        HStack {
            Spacer()
            SageCloseButton(action: { dismiss() })
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.top, DesignSystem.Spacing.medium)
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
                .padding(.bottom, DesignSystem.Spacing.small)
            
            Text(NSLocalizedString("upgrade_to_premium", comment: ""))
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(NSLocalizedString("paywall.description", comment: ""))
                .font(DesignSystem.Typography.bodyRegular)
                .multilineTextAlignment(.center)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, DesignSystem.Spacing.medium)
        }
        .padding(.top, DesignSystem.Spacing.medium)
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Group {
                switch iapService.offeringsLoadingState {
                case .loading:
                    ForEach(0..<2) { _ in
                        SubscriptionOptionPlaceholder()
                    }
                case .failed:
                    Text(NSLocalizedString("paywall.offerings.load_failed", comment: ""))
                        .font(DesignSystem.Typography.bodyRegular)
                        .foregroundColor(DesignSystem.Colors.error)
                        .padding(DesignSystem.Spacing.medium)
                default:
                    if let packages = iapService.offerings?.current?.availablePackages {
                        ForEach(packages, id: \.identifier) { package in
                            SubscriptionOptionView(
                                package: package,
                                isSelected: selectedPackage?.identifier == package.identifier,
                                isPopular: package.identifier == IAPConfiguration.yearlySubscriptionId,
                                action: { selectedPackage = package }
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.animation(.easeIn.delay(0.2)),
                                    removal: .opacity.animation(.easeOut)
                                )
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .animation(.easeInOut(duration: 0.3), value: iapService.offeringsLoadingState)
    }
    
    private var purchaseSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            purchaseButton
            
            linkButtonsRow
        }
        .padding(.horizontal, DesignSystem.Spacing.small)
        .padding(.bottom, DesignSystem.Spacing.medium)
    }
    
    private var purchaseButton: some View {
        Button(action: handlePurchase) {
            Text(buttonTitle)
                .font(DesignSystem.Typography.buttonLabel)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: PaywallDimensions.buttonHeight)
                .background(buttonBackground)
                .cornerRadius(PaywallDimensions.buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .disabled(iapService.isPremium || iapService.purchaseState == .purchasing || selectedPackage == nil)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .padding(.vertical, DesignSystem.Spacing.small)
    }
    
    private var linkButtonsRow: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            linkButton(
                title: "paywall.restore_purchases",
                action: handleRestore
            )
            
            divider
            
            linkButton(
                title: "paywall.terms",
                action: openTerms
            )
            
            divider
            
            linkButton(
                title: "paywall.privacy",
                action: openPrivacyPolicy
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.small)
    }
    
    private var divider: some View {
        Text("•")
            .foregroundColor(DesignSystem.Colors.tertiaryText)
    }
    
    private func linkButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(NSLocalizedString(title, comment: ""))
                .font(DesignSystem.Typography.bodyRegular)
                .foregroundColor(DesignSystem.Colors.link)
        }
        .buttonStyle(.plain)
        .withHoverEffect(scale: 1.1, brightness: 0.1)
    }
    
    private var subscriptionTermsText: some View {
        Text(LocalizedStringKey("paywall.subscription.terms"))
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.tertiaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .center)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "cancel" {
                    openCancelSubscription()
                    return .handled
                }
                return .systemAction
            })
            .tint(DesignSystem.Colors.link)
    }
    
    // MARK: - Helper Properties
    
    private var buttonTitle: String {
        if iapService.isPremium {
            return NSLocalizedString("paywall.button.subscribed", comment: "")
        }
        return iapService.purchaseState == .purchasing ? 
            NSLocalizedString("paywall.purchase.processing", comment: "") :
            NSLocalizedString("paywall.button.subscribe", comment: "")
    }
    
    private var buttonBackground: Color {
        iapService.isPremium ? DesignSystem.Colors.success : DesignSystem.Colors.primary
    }
    
    // MARK: - Actions
    
    private func refreshSubscriptionData() async {
        do {
            await iapService.lazyLoadOfferings()
            try await iapService.refreshCustomerInfo()
        } catch {
            print("[PaywallView] Failed to refresh subscription data: \(error)")
        }
    }
    
    private func handlePurchase() {
        guard !iapService.isPremium, let selectedPackage = selectedPackage else { return }
        
        Task {
            do {
                try await iapService.purchase(IAPProduct(package: selectedPackage))
                if iapService.isPremium {
                    onPurchaseCompleted()
                    showToast(message: "paywall.purchase.success")
                }
            } catch {
                if case .userCancelled = error as? IAPError {
                    iapService.clearError()
                } else {
                    showToast(message: "paywall.purchase.failed")
                }
            }
        }
    }
    
    private func handleRestore() {
        Task {
            do {
                let hasActiveSubscription = try await iapService.restorePurchases()
                let messageKey = hasActiveSubscription ? 
                    "paywall.restore.success" : 
                    "paywall.restore.no_subscription"
                showToast(message: messageKey)
            } catch {
                showToast(message: "paywall.restore.failed")
                print("Restore failed: \(error)")
            }
        }
    }
    
    private func showToast(message: String) {
        toastMessage = NSLocalizedString(message, comment: "")
        showToast = true
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openTerms() {
        openURL(AppConstants.URLs.userAgreement)
    }
    
    private func openPrivacyPolicy() {
        openURL(AppConstants.URLs.privacyPolicy)
    }
    
    private func openCancelSubscription() {
        openURL(AppConstants.URLs.cancelSubscription)
    }
    
    /// 默认选中月度订阅方案
    private func selectMonthlySubscription() {
        // 如果已经有选中的方案，不做改变
        if selectedPackage != nil {
            return
        }
        
        // 尝试获取月度订阅方案并选中
        if let monthlyPackage = iapService.package(withIdentifier: IAPConfiguration.monthlySubscriptionId) {
            selectedPackage = monthlyPackage
        } else {
            // 尝试通过包含关键字"monthly"或"month"来查找月度包
            if let packages = iapService.offerings?.current?.availablePackages {
                let monthlyPackages = packages.filter { 
                    $0.identifier.lowercased().contains("month") 
                }
                
                if let firstMonthlyPackage = monthlyPackages.first {
                    selectedPackage = firstMonthlyPackage
                } else if !packages.isEmpty {
                    // 如果找不到月度方案但有其他方案，选择第一个
                    selectedPackage = packages.first
                }
            }
        }
    }
}

// MARK: - Subscription Option View
struct SubscriptionOptionView: View {
    // MARK: - Properties
    let package: Package
    let isSelected: Bool
    let isPopular: Bool
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.small) {
                packageInfoView
                
                Spacer()
                
                priceAndSelectionView
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DesignSystem.Spacing.small)
    }
    
    // MARK: - Components
    
    private var packageInfoView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Text(package.storeProduct.localizedTitle)
                    .font(.headline)
                
                if isPopular {
                    bestValueBadge
                }
            }
            
            Text(package.storeProduct.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var bestValueBadge: some View {
        Text(NSLocalizedString("paywall.best_value", comment: ""))
            .font(.caption)
            .foregroundColor(.green)
            .padding(.horizontal, DesignSystem.Spacing.small)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)
    }
    
    private var priceAndSelectionView: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Text(package.storeProduct.localizedPriceString)
                .font(.headline)
                .foregroundColor(.primary)
            
            SubscriptionSelectionIndicator(isSelected: isSelected)
        }
    }
}

// MARK: - Subscription Selection Indicator
private struct SubscriptionSelectionIndicator: View {
    // MARK: - Properties
    let isSelected: Bool
    
    private enum Design {
        static let outerSize: CGFloat = 10
        static let innerSize: CGFloat = 10
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.2))
                .frame(width: Design.outerSize, height: Design.outerSize)
            
            if isSelected {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: Design.innerSize, height: Design.innerSize)
            }
        }
    }
}

// MARK: - Subscription Option Placeholder
struct SubscriptionOptionPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(placeholderColor)
                    .frame(width: 120, height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(placeholderColor)
                    .frame(width: 200, height: 16)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(placeholderColor)
                .frame(width: 60, height: 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
        .padding(.horizontal)
        .redacted(reason: .placeholder)
        .shimmering()
    }
    
    private var placeholderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
    }
}

// MARK: - Shimmering Effect
extension View {
    func shimmering() -> some View {
        self.modifier(ShimmeringEffect())
    }
}

struct ShimmeringEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.2),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2) * phase)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .onAppear {
                phase = 1
            }
            .clipped()
    }
}

// MARK: - Paywall Dimensions
private enum PaywallDimensions {
    static let containerWidth: CGFloat = 440
    static let containerHeight: CGFloat = 600
    static let buttonHeight: CGFloat = 44
    static let buttonCornerRadius: CGFloat = 8
}

// MARK: - Design System Extensions
extension DesignSystem.Spacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

#Preview {
    PaywallView(onPurchaseCompleted: {})
        .environmentObject(IAPService.shared)
} 
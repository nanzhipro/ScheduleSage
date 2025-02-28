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
// MARK: - Custom Paywall View for macOS
struct PaywallView: View {
    let onPurchaseCompleted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var iapService: IAPService
    @State private var selectedPackage: Package?
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: DesignSystem.Spacing.medium) {
                closeButton
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.large) {
                        headerSection
                        subscriptionOptionsSection
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            purchaseButton
                            
                            // 恢复购买按钮
                            Button(action: handleRestore) {
                                Text(NSLocalizedString("paywall.restore_purchases", comment: ""))
                                    .font(DesignSystem.Typography.bodyRegular)
                                    .foregroundColor(DesignSystem.Colors.link)
                            }
                            .buttonStyle(.plain)
                            .withHoverEffect(scale: 1.1, brightness: 0.1)
                            
                            // 服务条款和隐私政策按钮组
                            HStack(spacing: DesignSystem.Spacing.medium) {
                                Button(action: openTerms) {
                                    Text(NSLocalizedString("paywall.terms", comment: ""))
                                        .font(DesignSystem.Typography.bodyRegular)
                                        .foregroundColor(DesignSystem.Colors.link)
                                }
                                .buttonStyle(.plain)
                                .withHoverEffect(scale: 1.1, brightness: 0.1)
                                
                                Text("•")
                                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                                
                                Button(action: openPrivacyPolicy) {
                                    Text(NSLocalizedString("paywall.privacy", comment: ""))
                                        .font(DesignSystem.Typography.bodyRegular)
                                        .foregroundColor(DesignSystem.Colors.link)
                                }
                                .buttonStyle(.plain)
                                .withHoverEffect(scale: 1.1, brightness: 0.1)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.bottom, DesignSystem.Spacing.large)
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
            // 静默刷新订阅数据
            await refreshSubscriptionData()
        }
    }
    
    // MARK: - Subscription Refresh
    
    private func refreshSubscriptionData() async {
        do {
            await iapService.lazyLoadOfferings()
            try await iapService.refreshCustomerInfo()
        } catch {
            print("[PaywallView] Failed to refresh subscription data: \(error)")
        }
    }
    
    // MARK: - UI Components
    
    private var closeButton: some View {
        HStack(spacing: DesignSystem.Spacing.iconSpacing) {
            Spacer()
            SageCloseButton(action: { dismiss() })
        }
        .padding(.horizontal, DesignSystem.Spacing.large)
        .padding(.top, DesignSystem.Spacing.medium)
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.primary)
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
            if iapService.offeringsLoadingState == .loading {
                ForEach(0..<2) { _ in
                    SubscriptionOptionPlaceholder()
                }
            }
            
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
                            insertion: .opacity
                                .animation(.easeIn.delay(0.2)),
                            removal: .opacity
                                .animation(.easeOut)
                        )
                    )
                }
            }
            
            if iapService.offeringsLoadingState == .failed {
                Text(NSLocalizedString("paywall.offerings.load_failed", comment: ""))
                    .font(DesignSystem.Typography.bodyRegular)
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding(DesignSystem.Spacing.medium)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .animation(.easeInOut(duration: 0.3), value: iapService.offeringsLoadingState)
    }
    
    private var purchaseButton: some View {
        Button {
            handlePurchase()
        } label: {
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
    
    // MARK: - Helper Methods
    
    private func handlePurchase() {
        guard !iapService.isPremium, let selectedPackage = selectedPackage else { return }
        
        Task {
            do {
                try await iapService.purchase(IAPProduct(package: selectedPackage))
                if iapService.isPremium {
                    onPurchaseCompleted()
                    toastMessage = NSLocalizedString("paywall.purchase.success", comment: "")
                    showToast = true
                }
            } catch {
                if case .userCancelled = error as? IAPError {
                    iapService.clearError()
                } else {
                    toastMessage = NSLocalizedString("paywall.purchase.failed", comment: "")
                    showToast = true
                }
            }
        }
    }
    
    private func handleRestore() {
        Task {
            if iapService.isPremium {
                toastMessage = NSLocalizedString("paywall.restore.already_subscribed", comment: "")
                showToast = true
            } else {
                do {
                    let hasActiveSubscription = try await iapService.restorePurchases()
                    toastMessage = hasActiveSubscription ?
                        NSLocalizedString("paywall.restore.success", comment: "") :
                        NSLocalizedString("paywall.restore.no_subscription", comment: "")
                    showToast = true
                } catch {
                    print("Restore failed: \(error)")
                }
            }
        }
    }
    
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
    
    private func openTerms() {
        if let url = URL(string: AppConstants.URLs.userAgreement) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: AppConstants.URLs.privacyPolicy) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Subscription Option View
struct SubscriptionOptionView: View {
    let package: Package
    let isSelected: Bool
    let isPopular: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.small) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                        
                        if isPopular {
                            Text(NSLocalizedString("paywall.best_value", comment: ""))
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, DesignSystem.Spacing.small)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(package.storeProduct.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Text(package.storeProduct.localizedPriceString)
                    .font(.headline)
                    .foregroundColor(.primary)
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
}

// MARK: - Subscription Option Placeholder
struct SubscriptionOptionPlaceholder: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // 标题占位
                RoundedRectangle(cornerRadius: 4)
                    .fill(placeholderColor)
                    .frame(width: 120, height: 20)
                
                // 描述占位
                RoundedRectangle(cornerRadius: 4)
                    .fill(placeholderColor)
                    .frame(width: 200, height: 16)
            }
            
            Spacer()
            
            // 价格占位
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
    static let containerHeight: CGFloat = 520 // 调整为 AddScheduleView 高度的 80%
    static let buttonHeight: CGFloat = 44
    static let buttonCornerRadius: CGFloat = 8
}

// MARK: - Design System Extensions
extension DesignSystem.Spacing {
    static let small: CGFloat = 6
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
    static let extraLarge: CGFloat = 28
}

#Preview {
    PaywallView(onPurchaseCompleted: {})
        .environmentObject(IAPService.shared)
} 
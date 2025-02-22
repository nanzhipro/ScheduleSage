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
            VStack(spacing: DesignSystem.Spacing.vertical) {
                closeButton
                
                VStack(spacing: DesignSystem.Spacing.vertical) {
                    headerSection
                    // featuresSection
                    subscriptionOptionsSection
                    purchaseButton
                    footerSection
                }
            }
        }
        .frame(width: DesignSystem.Dimensions.containerWidth, height: DesignSystem.Dimensions.containerHeight)
        .background(DesignSystem.Colors.background)
        .toast(isPresented: $showToast, type: .success, message: toastMessage)
    }
    
    // MARK: - UI Components
    
    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            .withHoverEffect(scale: 1.2, brightness: 0.1)
        }
        .padding([.top, .trailing], 16)
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.textSpacing) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text(NSLocalizedString("upgrade_to_premium", comment: ""))
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(NSLocalizedString("paywall.description", comment: ""))
                .font(DesignSystem.Typography.bodyRegular)
                .multilineTextAlignment(.center)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(.top, DesignSystem.Spacing.vertical)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.textSpacing) {
            ForEach(PremiumFeatures.allCases, id: \.self) { feature in
                HStack(spacing: DesignSystem.Spacing.iconSpacing) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                    Text(feature.localizedDescription)
                        .font(DesignSystem.Typography.bodyRegular)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.horizontal)
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            // 占位视图
            if iapService.offeringsLoadingState == .loading {
                ForEach(0..<2) { _ in
                    SubscriptionOptionPlaceholder()
                }
            }
            
            // 实际内容
            if let packages = iapService.offerings?.current?.availablePackages {
                ForEach(packages, id: \.identifier) { package in
                    SubscriptionOptionView(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        isPopular: package.identifier == IAPConfiguration.yearlySubscriptionId,
                        action: { selectedPackage = package }
                    )
                    .transition(.opacity)
                }
            }
            
            // 错误状态
            if iapService.offeringsLoadingState == .failed {
                Text(NSLocalizedString("paywall.offerings.load_failed", comment: ""))
                    .font(DesignSystem.Typography.bodyRegular)
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding()
            }
        }
        .padding(.vertical, DesignSystem.Spacing.vertical)
        .animation(.easeInOut, value: iapService.offeringsLoadingState)
    }
    
    private var purchaseButton: some View {
        Button {
            handlePurchase()
        } label: {
            Text(buttonTitle)
                .font(DesignSystem.Typography.buttonLabel)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignSystem.Dimensions.buttonHeight)
                .background(buttonBackground)
                .cornerRadius(DesignSystem.Dimensions.buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .disabled(iapService.isPremium || iapService.purchaseState == .purchasing || selectedPackage == nil)
        .padding(.horizontal)
    }
    
    private var footerSection: some View {
        VStack(spacing: DesignSystem.Spacing.textSpacing) {
            restoreButton
            termsAndPrivacySection
        }
        .padding(.bottom)
    }
    
    private var restoreButton: some View {
        Button {
            handleRestore()
        } label: {
            Text(NSLocalizedString("paywall.restore_purchases", comment: ""))
                .font(DesignSystem.Typography.bodyRegular)
                .foregroundColor(DesignSystem.Colors.link)
        }
    }
    
    private var termsAndPrivacySection: some View {
        VStack(spacing: DesignSystem.Spacing.textSpacing) {
            Text(NSLocalizedString("paywall.footer.terms_privacy", comment: ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: DesignSystem.Spacing.iconSpacing) {
                Button(action: { /* Open Terms */ }) {
                    Text(NSLocalizedString("paywall.terms", comment: ""))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.link)
                }
                
                Button(action: { /* Open Privacy Policy */ }) {
                    Text(NSLocalizedString("paywall.privacy", comment: ""))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.link)
                }
            }
        }
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
}

// MARK: - Subscription Option View
struct SubscriptionOptionView: View {
    let package: Package
    let isSelected: Bool
    let isPopular: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                        
                        if isPopular {
                            Text(NSLocalizedString("paywall.best_value", comment: ""))
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(package.storeProduct.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(package.storeProduct.localizedPriceString)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
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

// MARK: - Premium Features
enum PremiumFeatures: CaseIterable {
    case unlimitedUsage
    case prioritySupport
    case earlyAccess
    
    var localizedDescription: String {
        switch self {
        case .unlimitedUsage:
            return NSLocalizedString("subscription_feature_unlimited_usage", comment: "")
        case .prioritySupport:
            return NSLocalizedString("subscription_feature_priority_support", comment: "")
        case .earlyAccess:
            return NSLocalizedString("subscription_feature_yearly_discount", comment: "")
        }
    }
}

#Preview {
    PaywallView(onPurchaseCompleted: {})
        .environmentObject(IAPService.shared)
} 
//
//  ProStatusView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024/03/26.
//

import SwiftUI

// MARK: - Pro Status View
struct ProStatusView: View {
  // MARK: - Properties
  let status: ProStatus
  let onUpgrade: () -> Void
  let style: Style

  @Environment(\.colorScheme) private var colorScheme

  // MARK: - Initialization
  init(
    status: ProStatus,
    onUpgrade: @escaping () -> Void,
    style: Style = .compact
  ) {
    self.status = status
    self.onUpgrade = onUpgrade
    self.style = style
  }

  // MARK: - Body
  var body: some View {
    switch style {
    case .compact:
      compactView
    case .expanded:
      expandedView
    }
  }

  // MARK: - Private Views
  private var compactView: some View {
    HStack(spacing: 8) {
      // Pro 图标
      ProBadge(isPro: status.isPro)

      if let remainingUses = status.remainingUses {
        // 剩余次数（非会员）
        Text(String(format: NSLocalizedString("remaining_uses", comment: ""), remainingUses))
          .font(DesignSystem.Typography.statusText)
          .foregroundColor(DesignSystem.Colors.secondaryText)

        Text(NSLocalizedString("separator", comment: ""))
          .font(DesignSystem.Typography.statusText)
          .foregroundColor(DesignSystem.Colors.secondaryText)
      }

      // 升级按钮
      if !status.isPro {
        Button(action: onUpgrade) {
          Text(NSLocalizedString("upgrade_to_pro", comment: ""))
            .font(DesignSystem.Typography.statusText)
            .foregroundColor(DesignSystem.Colors.primary)
        }
        .buttonStyle(.plain)
        .withHoverEffect()
      }
    }
  }

  private var expandedView: some View {
    VStack(alignment: .leading, spacing: 16) {
      // 状态头部
      HStack {
        ProBadge(isPro: status.isPro)
        Spacer()
        if !status.isPro {
          upgradeButton
        }
      }

      // 特性列表
      VStack(alignment: .leading, spacing: 12) {
        ForEach(status.features) { feature in
          FeatureRow(feature: feature)
        }
      }

      // 会员到期时间
      if let expiryDate = status.expiryDate {
        Text(
          String(
            format: NSLocalizedString("pro_expiry", comment: ""),
            DateFormatter.localizedString(from: expiryDate, dateStyle: .medium, timeStyle: .none)
          )
        )
        .font(DesignSystem.Typography.caption)
        .foregroundColor(DesignSystem.Colors.secondaryText)
      }
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
  }

  private var upgradeButton: some View {
    Button(action: onUpgrade) {
      Text(NSLocalizedString("upgrade_to_pro", comment: ""))
        .font(DesignSystem.Typography.buttonLabel)
        .foregroundColor(DesignSystem.Colors.background)
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(DesignSystem.Colors.primary)
        .cornerRadius(16)
    }
    .buttonStyle(.plain)
    .withHoverEffect()
  }
}

// MARK: - Supporting Views
private struct ProBadge: View {
  let isPro: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(DesignSystem.Colors.lightGray)
        .frame(
          width: DesignSystem.Dimensions.crownIconSize,
          height: DesignSystem.Dimensions.crownIconSize
        )
      Image(systemName: "crown.fill")
        .foregroundColor(isPro ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryGray)
    }
  }
}

private struct FeatureRow: View {
  let feature: ProFeature

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: feature.icon)
        .foregroundColor(DesignSystem.Colors.primary)
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(feature.name)
          .font(DesignSystem.Typography.bodyMedium)
        Text(feature.description)
          .font(DesignSystem.Typography.caption)
          .foregroundColor(DesignSystem.Colors.secondaryText)
      }
    }
  }
}

// MARK: - Style Configuration
extension ProStatusView {
  enum Style {
    case compact  // 紧凑模式，用于导航栏
    case expanded  // 展开模式，用于会员页面
  }
}

// MARK: - Preview
#if DEBUG
struct ProStatusView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // 免费用户 - 紧凑模式
      //            ProStatusView(
      //                status: .free(remainingUses: 12),
      //                onUpgrade: {},
      //                style: .compact
      //            )
      //            .padding()
      //            .previewDisplayName("Free User - Compact")
      //
      // Pro用户 - 展开模式
      ProStatusView(
        status: .unlimited,
        onUpgrade: {},
        style: .compact
      )
      .padding()
      .previewDisplayName("Pro User - Expanded")
    }
  }
}
#endif

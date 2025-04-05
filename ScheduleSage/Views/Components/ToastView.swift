//
//  ToastView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-21.
//

import SwiftUI

// MARK: - Toast Type
public enum ToastType {
  case success
  case error
  case info
}

// MARK: - Toast Position
public enum ToastPosition {
  case center
  case bottom
  case top
}

// MARK: - Toast Configuration
public struct ToastConfiguration {
  let type: ToastType
  let message: String
  let duration: TimeInterval
  let position: ToastPosition

  public init(
    type: ToastType,
    message: String,
    duration: TimeInterval = 2.0,
    position: ToastPosition = .center
  ) {
    self.type = type
    self.message = message
    self.duration = duration
    self.position = position
  }
}

// MARK: - Toast View
public struct ToastView: View {
  private let configuration: ToastConfiguration
  @Environment(\.colorScheme) private var colorScheme

  public init(configuration: ToastConfiguration) {
    self.configuration = configuration
  }

  public var body: some View {
    HStack(spacing: 8) {
      Image(systemName: iconName)
        .font(.system(size: 20))
        .foregroundColor(iconColor)

      Text(configuration.message)
        .font(DesignSystem.Typography.bodyRegular)
        .foregroundColor(textColor)
        .fixedSize(horizontal: false, vertical: true)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      ZStack {
        // 基础背景色 - 稍微降低不透明度以增强玻璃效果
        RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
          .fill(backgroundColor.opacity(0.85))

        // 添加磨砂玻璃效果
        if #available(macOS 12.0, *) {
          RoundedRectangle(cornerRadius: DesignSystem.Dimensions.cardCornerRadius)
            .fill(Material.regularMaterial)  // 使用较重的材质使Toast更加明显
            .opacity(colorScheme == .dark ? 0.4 : 0.3)
        }
      }
    )
    .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
    .shadow(
      color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
      radius: 10,
      x: 0,
      y: 4
    )
    .frame(maxWidth: 400)
    .frame(minWidth: 200)
  }

  private var backgroundColor: Color {
    switch configuration.type {
    case .success:
      return colorScheme == .dark ? DesignSystem.Colors.primary.opacity(0.9) : DesignSystem.Colors.primary
    case .error:
      return colorScheme == .dark ? DesignSystem.Colors.error.opacity(0.9) : DesignSystem.Colors.error
    case .info:
      return colorScheme == .dark ? DesignSystem.Colors.link.opacity(0.9) : DesignSystem.Colors.link
    }
  }

  private var iconName: String {
    switch configuration.type {
    case .success:
      return "checkmark.circle.fill"
    case .error:
      return "exclamationmark.circle.fill"
    case .info:
      return "info.circle.fill"
    }
  }

  private var iconColor: Color {
    switch configuration.type {
    case .success:
      return colorScheme == .dark ? DesignSystem.Colors.background.opacity(0.9) : DesignSystem.Colors.background
    case .error:
      return colorScheme == .dark ? DesignSystem.Colors.background.opacity(0.9) : DesignSystem.Colors.background
    case .info:
      return colorScheme == .dark ? DesignSystem.Colors.background.opacity(0.9) : DesignSystem.Colors.background
    }
  }

  private var textColor: Color {
    switch configuration.type {
    case .success, .error, .info:
      return colorScheme == .dark ? DesignSystem.Colors.background.opacity(0.9) : DesignSystem.Colors.background
    }
  }
}

// MARK: - Toast Container
public struct ToastContainer<Content: View>: View {
  @Binding private var isPresented: Bool
  private let configuration: ToastConfiguration
  private let content: Content

  public init(
    isPresented: Binding<Bool>,
    configuration: ToastConfiguration,
    @ViewBuilder content: () -> Content
  ) {
    self._isPresented = isPresented
    self.configuration = configuration
    self.content = content()
  }

  public var body: some View {
    ZStack {
      content

      if isPresented {
        positionedToast
          .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.duration) {
              isPresented = false
            }
          }
      }
    }
  }

  @ViewBuilder
  private var positionedToast: some View {
    switch configuration.position {
    case .center:
      ToastView(configuration: configuration)
    case .top:
      VStack {
        ToastView(configuration: configuration)
          .padding(.top, 20)
        Spacer()
      }
    case .bottom:
      VStack {
        Spacer()
        ToastView(configuration: configuration)
          .padding(.bottom, 20)
      }
    }
  }
}

// MARK: - View Extensions
public extension View {
  func toast(
    isPresented: Binding<Bool>,
    type: ToastType,
    message: String,
    duration: TimeInterval = 2.0,
    position: ToastPosition = .center
  ) -> some View {
    ToastContainer(
      isPresented: isPresented,
      configuration: .init(
        type: type,
        message: message,
        duration: duration,
        position: position
      )
    ) {
      self
    }
  }

  func localizedToast(
    isPresented: Binding<Bool>,
    type: ToastType,
    key: String,
    comment: String = "",
    duration: TimeInterval = 2.0,
    position: ToastPosition = .center
  ) -> some View {
    let localizedMessage = NSLocalizedString(key, comment: comment)
    return toast(
      isPresented: isPresented,
      type: type,
      message: localizedMessage,
      duration: duration,
      position: position
    )
  }
}

// MARK: - Preview Provider
#if DEBUG
struct ToastView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ToastView(configuration: .init(type: .success, message: "操作成功完成"))
        .previewDisplayName("Success Toast")

      ToastView(configuration: .init(type: .error, message: "发生错误，请重试"))
        .previewDisplayName("Error Toast")

      ToastView(configuration: .init(type: .info, message: "这是一个非常长的消息，用于测试自适应文本内容的显示效果。现在Toast应该能够正确地显示长文本而不会被截断。"))
        .previewDisplayName("Long Text Toast")

      DemoView()
        .previewDisplayName("Toast Container Demo")
    }
    .previewLayout(.sizeThatFits)
    .padding()
  }
}

private struct DemoView: View {
  @State private var showToast = false
  @State private var showLocalizedToast = false
  @State private var showCenterToast = false
  @State private var showTopToast = false

  var body: some View {
    VStack(spacing: 20) {
      Button("Show Bottom Toast") {
        showToast = true
      }

      Button("Show Localized Toast") {
        showLocalizedToast = true
      }

      Button("Show Center Toast") {
        showCenterToast = true
      }

      Button("Show Top Toast") {
        showTopToast = true
      }
    }
    .frame(width: 300, height: 300)
    .toast(
      isPresented: $showToast,
      type: .success,
      message: "这是底部Toast消息",
      position: .bottom
    )
    .localizedToast(
      isPresented: $showLocalizedToast,
      type: .error,
      key: "toast.error.network",
      comment: "Network error toast message",
      position: .bottom
    )
    .toast(
      isPresented: $showCenterToast,
      type: .info,
      message: "这是中央Toast消息"
    )
    .toast(
      isPresented: $showTopToast,
      type: .success,
      message: "这是顶部Toast消息",
      position: .top
    )
  }
}
#endif

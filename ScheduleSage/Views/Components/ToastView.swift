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
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return ScheduleDesignSystem.Colors.success
        case .error:
            return ScheduleDesignSystem.Colors.error
        }
    }
}

// MARK: - Toast Configuration
public struct ToastConfiguration {
    let type: ToastType
    let message: String
    let duration: TimeInterval
    
    public init(
        type: ToastType,
        message: String,
        duration: TimeInterval = 2.0
    ) {
        self.type = type
        self.message = message
        self.duration = duration
    }
}

// MARK: - Toast View
public struct ToastView: View {
    // MARK: - Constants
    private enum Constants {
        static let maxWidth: CGFloat = 300
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 20
        static let spacing: CGFloat = 8
        static let shadowRadius: CGFloat = 10
        static let shadowOpacity: Double = 0.1
    }
    
    // MARK: - Properties
    private let configuration: ToastConfiguration
    
    // MARK: - Initialization
    public init(configuration: ToastConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: Constants.spacing) {
            // Icon
            Image(systemName: configuration.type.icon)
                .font(.system(size: Constants.iconSize))
                .foregroundColor(.white)
            
            // Message
            Text(configuration.message)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(configuration.type.color)
        .cornerRadius(Constants.cornerRadius)
        .shadow(
            color: Color.black.opacity(Constants.shadowOpacity),
            radius: Constants.shadowRadius,
            x: 0,
            y: 4
        )
        .frame(maxWidth: Constants.maxWidth)
    }
}

// MARK: - Toast Container
public struct ToastContainer<Content: View>: View {
    // MARK: - Properties
    @Binding private var isPresented: Bool
    private let configuration: ToastConfiguration
    private let content: Content
    
    // MARK: - Initialization
    public init(
        isPresented: Binding<Bool>,
        configuration: ToastConfiguration,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.configuration = configuration
        self.content = content()
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    ToastView(configuration: configuration)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.duration) {
                                withAnimation(.spring(response: 0.3)) {
                                    isPresented = false
                                }
                            }
                        }
                    Spacer()
                }
                .padding(.top, 20)
            }
        }
        .animation(.spring(response: 0.3), value: isPresented)
    }
}

// MARK: - View Extension
public extension View {
    func toast(
        isPresented: Binding<Bool>,
        type: ToastType,
        message: String,
        duration: TimeInterval = 2.0
    ) -> some View {
        let configuration = ToastConfiguration(
            type: type,
            message: message,
            duration: duration
        )
        return ToastContainer(
            isPresented: isPresented,
            configuration: configuration
        ) {
            self
        }
    }
}

// MARK: - Preview Provider
#if DEBUG
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Success Toast
            ToastView(
                configuration: .init(
                    type: .success,
                    message: "操作成功完成"
                )
            )
            .previewDisplayName("Success Toast")
            
            // Error Toast with Long Message
            ToastView(
                configuration: .init(
                    type: .error,
                    message: "发生错误：无法完成操作，请检查网络连接并重试。如果问题持续存在，请联系支持团队。"
                )
            )
            .previewDisplayName("Error Toast with Long Message")
            
            // Toast Container Demo
            DemoView()
                .previewDisplayName("Toast Container Demo")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

// Demo View for Preview
private struct DemoView: View {
    @State private var showToast = false
    
    var body: some View {
        VStack {
            Button("Show Toast") {
                showToast = true
            }
        }
        .frame(width: 300, height: 200)
        .toast(
            isPresented: $showToast,
            type: .success,
            message: "这是一个测试消息"
        )
    }
}
#endif 
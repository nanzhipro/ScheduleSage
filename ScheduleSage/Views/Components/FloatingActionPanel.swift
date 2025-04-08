//
//  FloatingActionPanel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-05-15.
//

import SwiftUI

/// 悬浮操作面板
/// 提供一个悬浮于主界面之上的输入区域，包含文本输入框和底部操作按钮
struct FloatingActionPanel: View {
  // MARK: - Properties

  /// 环境变量
  @Environment(\.colorScheme) private var colorScheme

  /// 状态管理
  @State private var isHovered = false
  @State private var inputText = ""
  @State private var isProcessing = false
  @ObservedObject private var viewModel: AddScheduleViewModel

  /// 回调处理
  private let onSendText: (String) async throws -> Void

  // MARK: - Layout Constants
  private enum Layout {
    static let cornerRadius: CGFloat = 20
    static let panelWidth: CGFloat = 500
    static let minHeight: CGFloat = 80
    static let maxHeight: CGFloat = 120
    static let buttonSize: CGFloat = 32
    static let buttonSpacing: CGFloat = 12
    static let buttonAreaHeight: CGFloat = 48
    static let contentPadding = EdgeInsets(
      top: 24,
      leading: 16,
      bottom: buttonAreaHeight,
      trailing: 16
    )
  }

  // MARK: - Initialization
  init(viewModel: AddScheduleViewModel, onSendText: @escaping (String) async throws -> Void) {
    self.viewModel = viewModel
    self.onSendText = onSendText
  }

  // MARK: - Body
  var body: some View {
    ZStack {
      backgroundLayer
      contentLayer
      buttonLayer
    }
    .frame(width: Layout.panelWidth)
    .frame(minHeight: Layout.minHeight, maxHeight: Layout.maxHeight)
    .background(panelBackground)
    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    .shadow(
      color: shadowColor,
      radius: isHovered ? 16 : 12,
      x: 0,
      y: isHovered ? 6 : 4
    )
    .shadow(
      color: secondaryShadowColor,
      radius: 3,
      x: 0,
      y: 2
    )
    .onChange(of: viewModel.transcribedText) { _, newValue in
      if !newValue.isEmpty {
        // 如果输入框为空，直接设置文本
        if inputText.isEmpty {
          inputText = newValue
        }
        // 如果输入框不为空且不包含新识别的文本，则追加文本
        else if !inputText.contains(newValue) && !inputText.contains("\n" + newValue + "\n")
          && !inputText.hasSuffix("\n" + newValue) && !inputText.hasPrefix(newValue + "\n") && inputText != newValue
        {
          inputText += "\n" + newValue
        }
      }
    }
  }

  // MARK: - View Components

  /// 背景层
  private var backgroundLayer: some View {
    RoundedRectangle(cornerRadius: Layout.cornerRadius)
      .fill(Color.clear)
      .frame(width: Layout.panelWidth)
      .frame(minHeight: Layout.minHeight, maxHeight: Layout.maxHeight)
  }

  /// 内容层
  private var contentLayer: some View {
    VStack(spacing: 0) {
      TextEditor(text: $inputText)
        .font(DesignSystem.Typography.bodyRegular)
        .foregroundColor(DesignSystem.Colors.primaryText)
        .scrollContentBackground(.hidden)
        .background(placeholderView)
        .padding(Layout.contentPadding)
        .frame(maxHeight: .infinity)

      Spacer(minLength: 0)
    }
    .frame(maxHeight: .infinity)
  }

  /// 按钮层
  private var buttonLayer: some View {
    VStack {
      Spacer()
      HStack(spacing: Layout.buttonSpacing) {
        actionButtonGroup
        Spacer()
        sendButton
      }
      .frame(height: Layout.buttonAreaHeight)
      .padding(.horizontal, 16)
    }
  }

  /// 操作按钮组
  private var actionButtonGroup: some View {
    HStack(spacing: Layout.buttonSpacing) {
      clipboardButton
      imagePickerButton
      voiceInputButton
    }
  }

  /// 剪贴板按钮
  private var clipboardButton: some View {
    ActionButton(
      iconName: "doc.circle.fill",
      action: viewModel.checkClipboardContent
    )
  }

  /// 图片选择按钮
  private var imagePickerButton: some View {
    ActionButton(
      iconName: "photo.circle.fill",
      action: viewModel.handleImageSelection
    )
  }

  /// 语音输入按钮
  private var voiceInputButton: some View {
    ActionButton(
      iconName: viewModel.isRecording ? "mic.fill" : "mic.circle.fill",
      action: toggleVoiceRecognition,
      isRecording: viewModel.isRecording,
      isProcessing: isProcessing,
      viewModel: viewModel
    )
  }

  /// 发送按钮
  private var sendButton: some View {
    ActionButton(
      iconName: "arrow.up.circle.fill",
      action: { Task { await handleSendText() } },
      isRecording: nil,
      isProcessing: isProcessing
    )
    .disabled(isProcessing || inputText.isEmpty)
    .opacity(isProcessing || inputText.isEmpty ? 0.5 : 1.0)
  }

  /// 占位符视图
  private var placeholderView: some View {
    ZStack(alignment: .topLeading) {
      if inputText.isEmpty {
        Text(NSLocalizedString("schedule_input_placeholder", comment: ""))
          .font(DesignSystem.Typography.bodyRegular)
          .foregroundColor(DesignSystem.Colors.tertiaryText)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.leading, 12)
          .padding(.top, -24)
      }
    }
  }

  /// 面板背景
  private var panelBackground: some View {
    ZStack {
      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .fill(backgroundFillColor)

      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .fill(.ultraThinMaterial)
        .opacity(colorScheme == .dark ? 0.6 : 0.4)

      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .stroke(borderColor, lineWidth: 0.5)
    }
  }

  // MARK: - Computed Properties

  private var backgroundFillColor: Color {
    colorScheme == .dark
      ? DesignSystem.Colors.cardBackground.opacity(0.75)
      : Color.white.opacity(0.5)
  }

  private var borderColor: Color {
    let opacity = colorScheme == .dark ? 0.15 : 0.08
    return DesignSystem.Colors.primary.opacity(opacity)
  }

  private var shadowColor: Color {
    colorScheme == .dark
      ? DesignSystem.Colors.primary.opacity(isHovered ? 0.15 : 0.1)
      : Color.black.opacity(isHovered ? 0.12 : 0.08)
  }

  private var secondaryShadowColor: Color {
    colorScheme == .dark
      ? Color.black.opacity(0.25)
      : Color.black.opacity(0.05)
  }

  // MARK: - Actions

  /// 切换语音识别状态
  private func toggleVoiceRecognition() {
    if viewModel.isRecording {
      viewModel.stopVoiceRecognition()
    } else {
      // 开始新的语音识别前清除旧的识别文本
      viewModel.transcribedText = ""
      viewModel.startVoiceRecognition()
    }
  }

  /// 处理发送文本
  private func handleSendText() async {
    guard !inputText.isEmpty else { return }

    if viewModel.isRecording {
      viewModel.stopVoiceRecognition()
    }

    isProcessing = true
    LoadingManager.shared.show(.processing)

    let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    if let url = URL(string: trimmedInput), url.isValidWebURL {
      // 处理URL
      viewModel.handleURLContent(url)
      inputText = ""
    } else {
      // 处理普通文本
      do {
        try await onSendText(inputText)
        inputText = ""
      } catch {
        viewModel.showToastMessage(error.localizedDescription, type: .error)
      }
    }

    isProcessing = false
    LoadingManager.shared.hide()
  }
}

/// 操作按钮
private struct ActionButton: View {
  let iconName: String
  let action: () -> Void
  let isRecording: Bool?
  let isProcessing: Bool?
  let viewModel: AddScheduleViewModel?

  @State private var isHovered = false
  @State private var isPressed = false
  @Environment(\.colorScheme) private var colorScheme

  // 录音相关状态
  @State private var pulseAnimation = false
  @State private var hasSound = false
  @State private var ripples: [RippleState] = []

  // 倒计时相关状态
  private let maxRecordingTime: TimeInterval = 60  // 1分钟 = 60秒
  @State private var recordingTimer: Timer?
  @State private var currentRecordingTime: TimeInterval = 0

  /// 格式化剩余时间为 "分:秒" 格式
  private var formattedRemainingTime: String {
    let remaining = Int(maxRecordingTime - currentRecordingTime)
    let minutes = remaining / 60
    let seconds = remaining % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  init(
    iconName: String,
    action: @escaping () -> Void,
    isRecording: Bool? = nil,
    isProcessing: Bool? = nil,
    viewModel: AddScheduleViewModel? = nil
  ) {
    self.iconName = iconName
    self.action = action
    self.isRecording = isRecording
    self.isProcessing = isProcessing
    self.viewModel = viewModel
  }

  var body: some View {
    ZStack {
      // 录音状态下的脉动效果
      if isRecording == true {
        Circle()
          .stroke(Color.red.opacity(0.6), lineWidth: 1)
          .frame(width: 40, height: 40)
          .scaleEffect(pulseAnimation ? 1.2 : 1.0)
          .opacity(pulseAnimation ? 0.5 : 0.8)
          .animation(
            Animation.easeInOut(duration: 1.0)
              .repeatForever(autoreverses: true),
            value: pulseAnimation
          )
      }

      // 水波纹效果
      if isRecording == true {
        ForEach(ripples) { ripple in
          Circle()
            .stroke(Color.red.opacity(ripple.opacity), lineWidth: 1.5)
            .frame(width: ripple.scale, height: ripple.scale)
            .scaleEffect(ripple.scale / 32.0)
        }
      }

      // 主按钮
      Button(action: handleButtonTap) {
        ZStack {
          Image(systemName: iconName)
            .font(.system(size: isRecording == true ? 16 : 24))
            .foregroundStyle(
              LinearGradient(
                colors: [
                  isRecording == true ? Color.red : DesignSystem.Colors.primary,
                  isRecording == true ? Color.red.opacity(0.8) : DesignSystem.Colors.primary.opacity(0.8),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 32, height: 32)
        }
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.1 : 1.0))
      }
      .buttonStyle(.plain)
      .onHover { hovering in
        withAnimation(.easeInOut(duration: 0.2)) {
          isHovered = hovering
        }
      }
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
              isPressed = true
            }
          }
          .onEnded { _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
              isPressed = false
            }
          }
      )
      .disabled(isProcessing == true)
      .opacity(isProcessing == true ? 0.5 : 1.0)

      // 倒计时文本 - 仅在录音状态下显示
      if isRecording == true {
        VStack {
          Spacer(minLength: 36)
          Text(formattedRemainingTime)
            .font(.system(size: 8, weight: .semibold))
            .foregroundColor(.red)
            .padding(3)
            .background(Color.white.opacity(0.8))
            .cornerRadius(3)
            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
      }
    }
    .frame(width: 40, height: 40)
    .onChange(of: viewModel?.audioLevel) { oldValue, newValue in
      if isRecording == true, let level = newValue {
        let hasVoiceInput = level > 0.15
        if hasVoiceInput != hasSound {
          hasSound = hasVoiceInput
        }

        if hasVoiceInput {
          createRipple(strength: level)
        }
      }
    }
    .onChange(of: isRecording) { oldValue, newValue in
      if newValue == true {
        pulseAnimation = true
        startTimer()
      } else if newValue == false {
        pulseAnimation = false
        stopTimer()
        currentRecordingTime = 0
        ripples.removeAll()
      }
    }
    .onAppear {
      // 初始化状态，如果一开始就是录音状态，激活呼吸灯和倒计时
      if isRecording == true {
        pulseAnimation = true
        startTimer()
      }
    }
    .onDisappear {
      stopTimer()
    }
  }

  private func handleButtonTap() {
    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
      isPressed = true
    }

    action()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
        isPressed = false
      }
    }
  }

  private func createRipple(strength: Float) {
    let rippleId = UUID()
    let initialScale: CGFloat = 32.0
    let maxScale: CGFloat = 32.0 + CGFloat(strength * 20)

    let newRipple = RippleState(id: rippleId, scale: initialScale, opacity: 0.5)
    ripples.append(newRipple)

    withAnimation(.easeOut(duration: 0.8)) {
      if let index = ripples.firstIndex(where: { $0.id == rippleId }) {
        ripples[index].scale = maxScale
        ripples[index].opacity = 0.0
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      ripples.removeAll(where: { $0.id == rippleId })
    }
  }

  /// 启动计时器
  private func startTimer() {
    currentRecordingTime = 0
    stopTimer()

    recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      if currentRecordingTime < maxRecordingTime {
        currentRecordingTime += 1

        // 如果达到最大时间，则自动停止录制
        if currentRecordingTime >= maxRecordingTime {
          stopRecordingAndRecognize()
        }
      }
    }
  }

  /// 停止计时器
  private func stopTimer() {
    recordingTimer?.invalidate()
    recordingTimer = nil
  }

  /// 停止录音并进行识别
  private func stopRecordingAndRecognize() {
    guard isRecording == true else { return }

    // 如果是语音输入按钮，停止录音后会自动触发语音识别
    if let vm = viewModel, vm.isRecording {
      Task { @MainActor in
        // 停止计时器
        stopTimer()
        currentRecordingTime = 0

        // 停止录音并等待识别完成
        vm.stopVoiceRecognition()

        // 通知外部停止录音和进行识别
        action()
      }
    } else {
      // 对于其他按钮，只执行标准操作
      action()
    }
  }
}

#if DEBUG
struct FloatingActionPanel_Previews: PreviewProvider {
  static var previews: some View {
    FloatingActionPanel(viewModel: PreviewData.mockAddScheduleViewModel) { text in
      // Implementation of onSendText
    }
    .padding()
    .previewLayout(.sizeThatFits)
  }
}
#endif

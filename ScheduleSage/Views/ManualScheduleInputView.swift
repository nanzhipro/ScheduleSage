//
//  ManualScheduleInputView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import SwiftUI

/**
 手动输入日程页
 支持直接输入文本或 URL 链接，以及语音输入功能
 */
struct ManualScheduleInputView: View {
  // MARK: - 环境与绑定
  @Environment(\.dismiss) private var dismiss
  @Binding var isPresented: Bool
  @FocusState private var isFocused: Bool

  // MARK: - 状态管理
  @StateObject private var viewState = ManualInputViewState()
  @State private var showToast = false

  // MARK: - 依赖注入
  private let processInput: (String) async throws -> [CalendarEvent]
  private let viewModel: AddScheduleViewModel
  var onEventsProcessed: ([CalendarEvent]) -> Void

  // MARK: - 初始化
  init(
    isPresented: Binding<Bool>,
    processInput: @escaping (String) async throws -> [CalendarEvent],
    viewModel: AddScheduleViewModel,
    onEventsProcessed: @escaping ([CalendarEvent]) -> Void
  ) {
    self._isPresented = isPresented
    self.processInput = processInput
    self.viewModel = viewModel
    self.onEventsProcessed = onEventsProcessed
  }

  // MARK: - 布局常量
  private var viewSize: CGSize {
    CGSize(
      width: DesignSystem.Dimensions.mainViewWidth * 0.8,
      height: DesignSystem.Dimensions.mainViewHeight * 0.8
    )
  }

  // MARK: - 视图构建
  var body: some View {
    NavigationStack {
      ZStack {
        VStack(spacing: 0) {
          HeaderView(isPresented: $isPresented, viewModel: viewModel)

          ZStack(alignment: .bottom) {
            InputArea(text: $viewState.inputText, isFocused: _isFocused)

            VoiceButton(
              isRecording: viewModel.isRecording,
              isProcessing: viewState.isProcessing,
              action: handleVoiceButtonTap,
              viewModel: viewModel
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            .offset(y: 10)
          }

          Spacer()

          RecognizeButton(
            isProcessing: viewState.isProcessing,
            isDisabled: viewState.isProcessing || viewState.inputText.isEmpty,
            action: { Task { await processInputText() } },
            viewModel: viewModel
          )
        }
        .frame(width: viewSize.width, height: viewSize.height)
        .background(DesignSystem.Colors.background)
      }
      .toast(
        isPresented: $showToast,
        type: viewState.toastType,
        message: viewState.toastMessage,
        position: .center
      )
      .navigationDestination(isPresented: $viewState.navigateToEventList) {
        EventListView(
          events: viewState.processedEvents,
          onAdd: { viewState.navigateToEventList = false },
          onImport: { _ in },
          onBack: { viewState.navigateToEventList = false },
          onUpdate: viewModel.updateEvent,
          viewModel: viewModel
        )
      }
      .onChange(of: viewModel.showEventList) { _, newValue in
        if newValue {
          isPresented = false
        }
      }
      .onChange(of: viewModel.transcribedText) { _, newValue in
        viewState.updateInputText(with: newValue)
      }
      .onChange(of: viewModel.isRecording) { _, newValue in
        if !newValue {
          isFocused = true
        }
      }
      .onAppear(perform: setupView)
      .onDisappear(perform: cleanupView)
      .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
      .withLoading()
    }
  }

  private func setupView() {
    viewModel.toggleKeyboardMonitor(isEnabled: false)
    isFocused = true
    viewState.setupVoiceRecognitionObserver()
  }

  private func cleanupView() {
    viewModel.toggleKeyboardMonitor(isEnabled: true)
    if viewModel.isRecording {
      viewModel.stopVoiceRecognition()
    }
    viewState.removeVoiceRecognitionObserver()
  }

  private func handleVoiceButtonTap() {
    if viewModel.isRecording {
      viewModel.stopVoiceRecognition()
      // 当停止录制时，如果有录制内容，则自动开始处理
      if !viewModel.transcribedText.isEmpty {
        Task {
          await processInputText()
        }
      }
    } else {
      // 不再清除 inputText，仅清除 transcribedText 以准备新的语音识别
      viewModel.transcribedText = ""
      viewModel.startVoiceRecognition()
    }
  }

  private func processInputText() async {
    guard !viewState.inputText.isEmpty else { return }
    await viewState.processInput(
      inputText: viewState.inputText,
      processInput: processInput,
      handleURLContent: { url in
        viewModel.handleURLContent(url)
        isPresented = false
      },
      onEventsProcessed: { events in
        onEventsProcessed(events)
        isPresented = false
      },
      showToast: { type, message in
        viewState.toastType = type
        viewState.toastMessage = message
        showToast = true
      }
    )
  }
}

@MainActor
final class ManualInputViewState: ObservableObject {
  @Published var inputText = ""
  @Published var isProcessing = false
  @Published var navigateToEventList = false
  @Published var processedEvents: [CalendarEvent] = []
  @Published var toastType: ToastType = .error
  @Published var toastMessage = ""

  private var voiceRecognitionObserver: NSObjectProtocol?

  func updateInputText(with newValue: String) {
    if !newValue.isEmpty {
      // 更精确地检查是否已包含此文本
      // 1. 检查完整匹配
      // 2. 检查作为行的匹配 (前后有换行符或在开始/结束)
      if !inputText.contains(newValue) && !inputText.contains("\n" + newValue + "\n")
        && !inputText.hasSuffix("\n" + newValue) && !inputText.hasPrefix(newValue + "\n") && inputText != newValue
      {

        if !inputText.isEmpty {
          inputText += "\n" + newValue
        } else {
          inputText = newValue
        }
      }
    }
  }

  func setupVoiceRecognitionObserver() {
    voiceRecognitionObserver = NotificationCenter.default.addObserver(
      forName: Notification.Name("voiceRecognitionCompleted"),
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard
        let self = self,
        let text = notification.userInfo?["text"] as? String,
        !text.isEmpty
      else { return }

      // 使用统一的文本更新方法
      self.updateInputText(with: text)
    }
  }

  func removeVoiceRecognitionObserver() {
    if let observer = voiceRecognitionObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  func processInput(
    inputText: String,
    processInput: (String) async throws -> [CalendarEvent],
    handleURLContent: (URL) -> Void,
    onEventsProcessed: ([CalendarEvent]) -> Void,
    showToast: (ToastType, String) -> Void
  ) async {
    isProcessing = true
    LoadingManager.shared.show(.processing)

    let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    if let url = URL(string: trimmedInput), url.isValidWebURL {
      handleURLContent(url)
    } else {
      do {
        processedEvents = try await processInput(inputText)
        onEventsProcessed(processedEvents)
      } catch {
        showToast(.error, error.localizedDescription)
      }
    }

    isProcessing = false
    LoadingManager.shared.hide()
  }
}

// MARK: - 子视图组件

/// 页面标题和关闭按钮
private struct HeaderView: View {
  @Binding var isPresented: Bool
  @ObservedObject var viewModel: AddScheduleViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.largeHeaderSpacing) {
      HStack(spacing: DesignSystem.Spacing.iconSpacing) {
        Text(NSLocalizedString("manual_input_title", comment: ""))
          .font(DesignSystem.Typography.largeHeaderTitle)
          .foregroundColor(DesignSystem.Colors.primaryText)
        Spacer()
        SageCloseButton(action: {
          // 关闭按钮点击时停止语音录入
          if viewModel.isRecording {
            viewModel.stopVoiceRecognition()
          }
          isPresented = false
        })
      }

      Text(NSLocalizedString("manual_input_subtitle", comment: ""))
        .font(DesignSystem.Typography.largeHeaderSubtitle)
        .foregroundColor(DesignSystem.Colors.secondaryText)
        .lineLimit(2)
    }
    .padding(.horizontal, DesignSystem.Layout.largeContainerPadding.leading)
    .padding(.top, DesignSystem.Layout.largeContainerPadding.top)
    .padding(.bottom, DesignSystem.Spacing.sectionSpacing)
  }
}

/// 文本输入区域
private struct InputArea: View {
  // MARK: - 属性
  @Binding var text: String
  @FocusState var isFocused: Bool

  var body: some View {
    ZStack(alignment: .topLeading) {
      // 文本输入区域
      TextEditor(text: $text)
        .font(DesignSystem.Typography.bodyRegular)
        .focused($isFocused)
        .scrollContentBackground(.hidden)
        .background(placeholderView)
        .padding(DesignSystem.Spacing.contentPadding)
        .background(DesignSystem.Colors.lightGray)
        .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
        .onExitCommand {
          isFocused = false
        }
        .textEditorStyle(.automatic)
    }
    .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
  }

  /// 输入占位符视图
  private var placeholderView: some View {
    ZStack(alignment: .topLeading) {
      if text.isEmpty && !isFocused {
        Text(NSLocalizedString("schedule_input_placeholder", comment: ""))
          .font(DesignSystem.Typography.bodyRegular)
          .foregroundColor(DesignSystem.Colors.tertiaryText)
          .padding(.top, -24)
          .padding(.leading, 12)
      }
    }
  }
}

/// 识别按钮
private struct RecognizeButton: View {
  let isProcessing: Bool
  let isDisabled: Bool
  let action: () -> Void
  @ObservedObject var viewModel: AddScheduleViewModel

  var body: some View {
    Button(action: {
      // 点击识别按钮时停止语音录入
      if viewModel.isRecording {
        viewModel.stopVoiceRecognition()
      }

      action()
    }) {
      HStack {
        Text(NSLocalizedString("recognize_button", comment: ""))
          .font(DesignSystem.Typography.buttonLabel)
          .foregroundColor(DesignSystem.Colors.background)
      }
      .frame(maxWidth: .infinity)
      .frame(height: DesignSystem.Dimensions.buttonHeight)
      .background(isDisabled ? DesignSystem.Colors.primary.opacity(0.5) : DesignSystem.Colors.primary)
      .cornerRadius(DesignSystem.Dimensions.buttonCornerRadius)
    }
    .buttonStyle(.plain)
    .withHoverEffect(scale: 1.02, brightness: 0.05)
    .disabled(isDisabled)
    .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
    .padding(.bottom, DesignSystem.Layout.containerPadding.bottom)
    .padding(.top, DesignSystem.Spacing.vertical)
  }
}

/// 麦克风按钮组件
private struct VoiceButton: View {
  // MARK: - 属性

  /// 外部录音状态
  let isRecording: Bool

  /// 文本处理状态
  let isProcessing: Bool

  /// 按钮点击事件回调
  let action: () -> Void

  /// 音量级别数据源
  @ObservedObject var viewModel: AddScheduleViewModel

  // MARK: - 本地状态

  /// 本地UI录音状态
  @State private var localRecordingState = false

  // MARK: - 动画状态
  @State private var buttonScale: CGFloat = 1.0
  @State private var isPressing = false
  @State private var pulseAnimation = false

  // 水波纹动画状态
  @State private var ripples: [RippleState] = []
  @State private var hasSound = false

  // 倒计时相关状态
  private let maxRecordingTime: TimeInterval = 59  // 1分钟 = 60秒
  @State private var recordingTimer: Timer?
  @State private var currentRecordingTime: TimeInterval = 0

  /// 计算按钮是否应该被禁用
  private var isDisabled: Bool {
    isProcessing
  }

  /// 格式化剩余时间为 "分:秒" 格式
  private var formattedRemainingTime: String {
    let remaining = Int(maxRecordingTime - currentRecordingTime)
    let minutes = remaining / 60
    let seconds = remaining % 60
    return String(format: "%d:%02d", minutes, seconds)
  }

  var body: some View {
    ZStack {
      // 脉动外圈 - 录音状态下显示
      if localRecordingState {
        Circle()
          .stroke(Color.red.opacity(0.6), lineWidth: 1)
          .frame(width: 60, height: 60)
          .scaleEffect(pulseAnimation ? 1.2 : 1.0)
          .opacity(pulseAnimation ? 0.5 : 0.8)
          .animation(
            Animation.easeInOut(duration: 1.0)
              .repeatForever(autoreverses: true),
            value: pulseAnimation
          )
          .onAppear {
            pulseAnimation = true
          }
          .onDisappear {
            pulseAnimation = false
          }
      }

      // 水波纹动画层
      ForEach(ripples) { ripple in
        Circle()
          .stroke(Color.red.opacity(ripple.opacity), lineWidth: 1.5)
          .frame(width: ripple.scale, height: ripple.scale)
          .scaleEffect(ripple.scale / 45.0)  // 从按钮边缘开始
      }

      // 录音中的视觉效果
      if localRecordingState {
        recordingEffects
      }

      // 按钮
      actionButton

      // 倒计时文本 - 移至ZStack最后，确保显示在最上层
      if localRecordingState {
        VStack {
          Spacer(minLength: 70)
          Text(formattedRemainingTime)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.red)
            .padding(4)
            .background(Color.white.opacity(0.8))
            .cornerRadius(4)
            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
      }
    }
    .frame(width: 60, height: 60)
    .onChange(of: isRecording) { oldValue, newValue in
      synchronizeExternalState(newValue)
    }
    .onAppear(perform: initializeState)
    .onChange(of: viewModel.audioLevel) { oldValue, newValue in
      // 根据声音级别更新hasSound状态
      if localRecordingState {
        let hasVoiceInput = newValue > 0.15
        if hasVoiceInput != hasSound {
          hasSound = hasVoiceInput
        }

        // 只有当有声音输入时创建新的水波纹
        if hasVoiceInput {
          createRipple(strength: newValue)
        }
      }
    }
    .onDisappear {
      stopTimer()
    }
  }

  // MARK: - 子视图

  /// 录音状态的视觉效果
  private var recordingEffects: some View {
    Group {
      // 录音状态基础指示器
      Circle()
        .fill(Color.red.opacity(0.2))
        .frame(width: 36, height: 36)

      // 当有声音输入时显示音量指示器
      if hasSound {
        Circle()
          .trim(from: 0, to: CGFloat(min(viewModel.audioLevel * 1.2, 1.0)))
          .stroke(Color.red, lineWidth: 2)
          .frame(width: 42, height: 42)
          .rotationEffect(.degrees(-90))
          .animation(.easeOut(duration: 0.1), value: viewModel.audioLevel)
      }
    }
  }

  /// 按钮视图
  private var actionButton: some View {
    Button(action: handleButtonTap) {
      // 麦克风图标
      ZStack {
        Image(systemName: localRecordingState ? "mic.fill" : "microphone.circle.fill")
          .font(.system(size: localRecordingState ? 28 : 36))
          .foregroundColor(localRecordingState ? Color.red : DesignSystem.Colors.primary)
          .opacity(isDisabled ? 0.5 : 1.0)
      }
      .frame(width: 45, height: 45)
    }
    .buttonStyle(.plain)
    .scaleEffect(buttonScale)
    .withHoverEffect(scale: isDisabled || isPressing ? 1.0 : 1.05, brightness: 0.05)
    .disabled(isDisabled)
  }

  // MARK: - 方法

  /// 处理按钮点击
  private func handleButtonTap() {
    // 当按钮禁用时不响应
    if isDisabled {
      return
    }

    // 轻微触感动画
    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
      isPressing = true
      buttonScale = 0.95
    }

    // 立即切换本地UI状态
    withAnimation(.easeInOut(duration: 0.2)) {
      localRecordingState.toggle()

      if localRecordingState {
        // 如果开始录音，启动计时器
        startTimer()
      } else {
        // 如果停止录音，停止计时器
        stopTimer()
        currentRecordingTime = 0
        hasSound = false
      }
    }

    // 执行操作
    action()

    // 延迟恢复原始大小
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
        isPressing = false
        buttonScale = 1.0
      }
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
          handleButtonTap()  // 自动触发按钮点击以停止录制
        }
      }
    }
  }

  /// 停止计时器
  private func stopTimer() {
    recordingTimer?.invalidate()
    recordingTimer = nil
  }

  /// 与外部状态同步
  private func synchronizeExternalState(_ newValue: Bool) {
    // 只有在外部状态与本地状态不一致时才更新
    if localRecordingState != newValue {
      withAnimation(.easeInOut(duration: 0.2)) {
        localRecordingState = newValue

        // 如果开始录音，启动计时器和脉动动画
        if newValue {
          pulseAnimation = true
          startTimer()
        }
        // 如果停止录音，停止计时器、清空声音状态和波纹
        else {
          pulseAnimation = false
          stopTimer()
          currentRecordingTime = 0
          hasSound = false
          ripples.removeAll()
        }
      }
    }
  }

  /// 初始化状态
  private func initializeState() {
    if localRecordingState != isRecording {
      localRecordingState = isRecording

      // 如果初始状态是录音中，启动计时器
      if localRecordingState {
        startTimer()
      }
    }
  }

  /// 创建新的水波纹
  private func createRipple(strength: Float) {
    let rippleId = UUID()
    let initialScale: CGFloat = 45.0  // 从按钮边缘开始
    let maxScale: CGFloat = 40.0 + CGFloat(strength * 30)  // 根据音量强度调整最大扩散范围，但更轻微

    // 创建新的水波纹
    let newRipple = RippleState(id: rippleId, scale: initialScale, opacity: 0.5)
    ripples.append(newRipple)

    // 水波纹扩散动画
    withAnimation(.easeOut(duration: 0.8)) {
      if let index = ripples.firstIndex(where: { $0.id == rippleId }) {
        ripples[index].scale = maxScale
        ripples[index].opacity = 0.0
      }
    }

    // 动画结束后移除水波纹
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
      ripples.removeAll(where: { $0.id == rippleId })
    }
  }
}

#if DEBUG
struct ManualScheduleInputView_Previews: PreviewProvider {
  static var previews: some View {
    ManualScheduleInputView(
      isPresented: .constant(true),
      processInput: { _ in [] },
      viewModel: PreviewData.mockAddScheduleViewModel
    ) { _ in }
  }
}
#endif

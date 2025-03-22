//
//  ManualScheduleInputView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

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
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var showToast = false
    @State private var toastType: ToastType = .error
    @State private var toastMessage = ""
    @State private var navigateToEventList = false
    @State private var processedEvents: [CalendarEvent] = []
    
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
                        // 输入区域
                        InputArea(text: $inputText, isFocused: _isFocused)
                        
                        // 语音按钮居中放置在下方
                        VoiceButton(
                            isRecording: viewModel.isRecording,
                            action: {
                                if viewModel.isRecording {
                                    viewModel.stopSpeechRecognition()
                                } else {
                                    inputText = ""
                                    viewModel.transcribedText = ""
                                    viewModel.startSpeechRecognition()
                                }
                            },
                            viewModel: viewModel
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(y: 30)
                    }
                    
                    Spacer()
                    
                    RecognizeButton(
                        isProcessing: isProcessing,
                        isDisabled: isProcessing || inputText.isEmpty,
                        action: { Task { await processInputText() } },
                        viewModel: viewModel
                    )
                }
                .frame(
                    width: viewSize.width,
                    height: viewSize.height
                )
                .background(DesignSystem.Colors.background)
            }
            .toast(
                isPresented: $showToast,
                type: toastType,
                message: toastMessage,
                position: .center
            )
            .navigationDestination(isPresented: $navigateToEventList) {
                EventListView(
                    events: processedEvents,
                    onAdd: { navigateToEventList = false },
                    onImport: { _ in },
                    onBack: { navigateToEventList = false },
                    onUpdate: viewModel.updateEvent,
                    viewModel: viewModel
                )
            }
            .onChange(of: viewModel.showEventList) { newValue in
                if newValue {
                    isPresented = false
                }
            }
            .onChange(of: viewModel.transcribedText) { newValue in
                // 当有新的转录文本时，直接替换现有文本
                if !newValue.isEmpty && viewModel.isRecording {
                    inputText = newValue
                }
            }
            .onChange(of: viewModel.isRecording) { newValue in
                if !newValue && !viewModel.transcribedText.isEmpty {
                    // 停止录音后保留文本，但不自动识别
                    if !inputText.contains(viewModel.transcribedText) {
                        if !inputText.isEmpty {
                            inputText += "\n" + viewModel.transcribedText
                        } else {
                            inputText = viewModel.transcribedText
                        }
                    }
                    // 聚焦到输入框，方便用户编辑
                    isFocused = true
                }
            }
            .onAppear {
                viewModel.toggleKeyboardMonitor(isEnabled: false)
                isFocused = true
            }
            .onDisappear {
                viewModel.toggleKeyboardMonitor(isEnabled: true)
                // 确保在视图消失时停止录音
                if viewModel.isRecording {
                    viewModel.stopSpeechRecognition()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
        }
    }
    
    // MARK: - 事件处理
    
    /// 处理输入文本并执行相应操作
    /// - 如果输入为URL，则直接处理URL内容
    /// - 否则，尝试解析输入文本并生成日历事件
    private func processInputText() async {
        guard !inputText.isEmpty else { return }
        isProcessing = true
        
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmedInput), url.isValidWebURL {
            viewModel.handleURLContent(url)
            isPresented = false
        } else {
            do {
                processedEvents = try await processInput(inputText)
                onEventsProcessed(processedEvents)
                isPresented = false
            } catch {
                toastType = .error
                toastMessage = error.localizedDescription
                showToast = true
            }
        }
        
        isProcessing = false
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
                        viewModel.stopSpeechRecognition()
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
                    .padding(.top, 8)
                    .padding(.leading, 5)
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
                viewModel.stopSpeechRecognition()
            }
            action()
        }) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(DesignSystem.Colors.background)
                }
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
    
    // 水波纹动画状态
    @State private var ripples: [RippleState] = []
    @State private var hasSound = false
    
    var body: some View {
        ZStack {
            // 水波纹动画层
            ForEach(ripples) { ripple in
                Circle()
                    .stroke(Color.red.opacity(ripple.opacity), lineWidth: 1.5)
                    .frame(width: ripple.scale, height: ripple.scale)
                    .scaleEffect(ripple.scale / 45.0) // 从按钮边缘开始
            }
            
            // 录音中的视觉效果
            if localRecordingState {
                recordingEffects
            }
            
            // 按钮
            actionButton
        }
        .frame(width: 60, height: 60)
        .onChange(of: isRecording) { newValue in
            synchronizeExternalState(newValue)
        }
        .onAppear(perform: initializeState)
        .onChange(of: viewModel.audioLevel) { newLevel in
            // 根据声音级别更新hasSound状态
            if localRecordingState {
                let hasVoiceInput = newLevel > 0.15
                if hasVoiceInput != hasSound {
                    hasSound = hasVoiceInput
                }
                
                // 只有当有声音输入时创建新的水波纹
                if hasVoiceInput {
                    createRipple(strength: newLevel)
                }
            }
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
                // 录音中的背景
                Circle()
                    .fill(localRecordingState ? Color.red.opacity(0.2) : Color.white)
                    .frame(width: 45, height: 45)
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)
                
                Image(systemName: localRecordingState ? "mic.fill" : "mic.circle.fill")
                    .font(.system(size: localRecordingState ? 20 : 24))
                    .foregroundColor(localRecordingState ? Color.red : DesignSystem.Colors.primary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(buttonScale)
        .withHoverEffect(scale: isPressing ? 1.0 : 1.05, brightness: 0.05)
    }
    
    // MARK: - 方法
    
    /// 处理按钮点击
    private func handleButtonTap() {
        // 轻微触感动画
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            isPressing = true
            buttonScale = 0.95
        }
        
        // 立即切换本地UI状态
        withAnimation(.easeInOut(duration: 0.2)) {
            localRecordingState.toggle()
            // 如果停止录音，清空声音状态
            if !localRecordingState {
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
    
    /// 与外部状态同步
    private func synchronizeExternalState(_ newValue: Bool) {
        // 只有在外部状态与本地状态不一致时才更新
        if localRecordingState != newValue {
            withAnimation(.easeInOut(duration: 0.2)) {
                localRecordingState = newValue
                
                // 如果停止录音，清空声音状态和波纹
                if !newValue {
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
        }
    }
    
    /// 创建新的水波纹
    private func createRipple(strength: Float) {
        let rippleId = UUID()
        let initialScale: CGFloat = 45.0 // 从按钮边缘开始
        let maxScale: CGFloat = 40.0 + CGFloat(strength * 30) // 根据音量强度调整最大扩散范围，但更轻微
        
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

// MARK: - 辅助结构体

/// 水波纹状态
struct RippleState: Identifiable {
    var id: UUID
    var scale: CGFloat
    var opacity: Double
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

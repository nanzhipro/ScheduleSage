//
//  ManualScheduleInputView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//  Created by CursorAI on 2024-07-xx.  // 当前日期
//

import SwiftUI

/**
 手动输入日程页
 支持直接输入文本或 URL 链接
 */
struct ManualScheduleInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var inputState = InputState()
    @FocusState private var isFocused: Bool
    
    private let llmProcessor: LLMEventProcessor
    private let viewModel: AddScheduleViewModel
    var onEventsProcessed: ([CalendarEvent]) -> Void
    
    init(
        llmProcessor: LLMEventProcessor,
        viewModel: AddScheduleViewModel,
        onEventsProcessed: @escaping ([CalendarEvent]) -> Void
    ) {
        self.llmProcessor = llmProcessor
        self.viewModel = viewModel
        self.onEventsProcessed = onEventsProcessed
    }
    
    // 计算尺寸
    private var viewSize: CGSize {
        CGSize(
            width: DesignSystem.Dimensions.mainViewWidth * 0.8,
            height: DesignSystem.Dimensions.mainViewHeight * 0.8
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView(dismiss: dismiss)
                InputArea(
                    text: $inputState.inputText,
                    isFocused: $isFocused
                )
                Spacer()
                RecognizeButton(
                    isProcessing: inputState.isProcessing,
                    isDisabled: inputState.isProcessing || inputState.inputText.isEmpty,
                    action: { Task { await processInput() } }
                )
            }
            .frame(
                width: viewSize.width,
                height: viewSize.height
            )
            .background(DesignSystem.Colors.background)
            .toolbar {
                ToolbarItemGroup {
                    Button(action: {
                        inputState.inputText = ""
                    }) {
                        Label(NSLocalizedString("clear_text", comment: ""), systemImage: "trash")
                    }
                    .disabled(inputState.inputText.isEmpty)
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(inputState.inputText, forType: .string)
                    }) {
                        Label(NSLocalizedString("copy_text", comment: ""), systemImage: "doc.on.doc")
                    }
                    .disabled(inputState.inputText.isEmpty)
                    
                    Button(action: {
                        if let text = NSPasteboard.general.string(forType: .string) {
                            inputState.inputText = text
                        }
                    }) {
                        Label(NSLocalizedString("paste_text", comment: ""), systemImage: "doc.on.clipboard")
                    }
                }
            }
            .toast(
                isPresented: $inputState.showToast,
                type: inputState.toastType,
                message: inputState.toastMessage
            )
            .navigationDestination(isPresented: $inputState.navigateToEventList) {
                EventListView(
                    events: inputState.processedEvents,
                    onAdd: { inputState.navigateToEventList = false },
                    onImport: {},
                    onBack: { inputState.navigateToEventList = false },
                    onUpdate: viewModel.updateEvent
                )
            }
            .onChange(of: viewModel.showEventList) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            }
            .onAppear {
                viewModel.disableKeyboardMonitor()
                isFocused = true
            }
            .onDisappear {
                viewModel.enableKeyboardMonitor()
            }
        }
    }
    
    private func processInput() async {
        guard !inputState.inputText.isEmpty else { return }
        inputState.isProcessing = true
        
        let trimmedInput = inputState.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmedInput), url.isValidWebURL {
            viewModel.handleURLContent(url)
            dismiss()
        } else {
            do {
                inputState.processedEvents = try await llmProcessor.processContent(inputState.inputText)
                onEventsProcessed(inputState.processedEvents)
                dismiss()
            } catch {
                inputState.toastType = .error
                inputState.toastMessage = error.localizedDescription
                inputState.showToast = true
            }
        }
        
        inputState.isProcessing = false
    }
}

// MARK: - Input State
private class InputState: ObservableObject {
    @Published var inputText = ""
    @Published var isProcessing = false
    @Published var showToast = false
    @Published var toastType: ToastType = .error
    @Published var toastMessage = ""
    @Published var navigateToEventList = false
    @Published var processedEvents: [CalendarEvent] = []
}

// MARK: - Subviews
private struct HeaderView: View {
    let dismiss: DismissAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.largeHeaderSpacing) {
            HStack(spacing: DesignSystem.Spacing.iconSpacing) {
                Text(NSLocalizedString("manual_input_title", comment: ""))
                    .font(DesignSystem.Typography.largeHeaderTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                SageCloseButton(action: { dismiss() })
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

private struct InputArea: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        TextEditor(text: $text)
            .font(DesignSystem.Typography.bodyRegular)
            .focused(isFocused)
            .scrollContentBackground(.hidden)
            .background(placeholderView)
            .padding(DesignSystem.Spacing.contentPadding)
            .background(DesignSystem.Colors.lightGray)
            .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
            .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
    }
    
    private var placeholderView: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty && !isFocused.wrappedValue {
                Text(NSLocalizedString("schedule_input_placeholder", comment: ""))
                    .font(DesignSystem.Typography.bodyRegular)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
        }
    }
}

private struct RecognizeButton: View {
    let isProcessing: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
            .background(DesignSystem.Colors.primary)
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

#if DEBUG
struct ManualScheduleInputView_Previews: PreviewProvider {
    static var previews: some View {
        ManualScheduleInputView(
            llmProcessor: PreviewData.mockLLMProcessor,
            viewModel: PreviewData.mockAddScheduleViewModel
        ) { _ in }
    }
}
#endif 

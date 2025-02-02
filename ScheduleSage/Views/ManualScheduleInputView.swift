//
//  ManualScheduleInputView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/**
 手动输入日程页
 支持直接输入文本或 URL 链接
 */
struct ManualScheduleInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var showToast = false
    @State private var toastType: ToastType = .error
    @State private var toastMessage = ""
    @State private var navigateToEventList = false
    @State private var processedEvents: [CalendarEvent] = []
    @FocusState private var isFocused: Bool
    
    private let llmProcessor: LLMEventProcessor
    private let viewModel: AddScheduleViewModel
    var onEventsProcessed: ([CalendarEvent]) -> Void
    
    init(isPresented: Binding<Bool>, 
         llmProcessor: LLMEventProcessor, 
         viewModel: AddScheduleViewModel,
         onEventsProcessed: @escaping ([CalendarEvent]) -> Void) {
        self._isPresented = isPresented
        self.llmProcessor = llmProcessor
        self.viewModel = viewModel
        self.onEventsProcessed = onEventsProcessed
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView(isPresented: $isPresented)
                InputArea(text: $inputText, isFocused: _isFocused)
                Spacer()
                RecognizeButton(
                    isProcessing: isProcessing,
                    isDisabled: isProcessing || inputText.isEmpty,
                    action: { Task { await processInput() } }
                )
            }
            .frame(width: 440, height: 360)
            .background(DesignSystem.Colors.background)
            .toast(
                isPresented: $showToast,
                type: toastType,
                message: toastMessage
            )
            .navigationDestination(isPresented: $navigateToEventList) {
                EventListView(
                    events: processedEvents,
                    onAdd: { navigateToEventList = false },
                    onImport: {},
                    onBack: { navigateToEventList = false },
                    onUpdate: viewModel.updateEvent
                )
            }
            .onChange(of: viewModel.showEventList) { oldValue, newValue in
                if newValue {
                    isPresented = false
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
        guard !inputText.isEmpty else { return }
        isProcessing = true
        
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmedInput), url.isValidWebURL {
            viewModel.handleURLContent(url)
            isPresented = false
        } else {
            do {
                processedEvents = try await llmProcessor.processContent(inputText)
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

// MARK: - Subviews
private struct HeaderView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.textSpacing) {
            HStack(spacing: DesignSystem.Spacing.iconSpacing) {
                Text(NSLocalizedString("manual_input_title", comment: ""))
                    .font(DesignSystem.Typography.headerTitle)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                Spacer()
                SageCloseButton(action: { isPresented = false })
            }
            
            Text(NSLocalizedString("manual_input_subtitle", comment: ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(2)
        }
        .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
        .padding(.top, DesignSystem.Layout.containerPadding.top)
        .padding(.bottom, DesignSystem.Spacing.sectionSpacing)
    }
}

private struct InputArea: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .font(DesignSystem.Typography.bodyRegular)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .background(placeholderView)
            .padding(DesignSystem.Spacing.contentPadding)
            .background(DesignSystem.Colors.lightGray)
            .cornerRadius(DesignSystem.Dimensions.cardCornerRadius)
            .padding(.horizontal, DesignSystem.Layout.containerPadding.leading)
    }
    
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
            isPresented: .constant(true),
            llmProcessor: PreviewData.mockLLMProcessor,
            viewModel: PreviewData.mockAddScheduleViewModel
        ) { _ in }
    }
}
#endif 

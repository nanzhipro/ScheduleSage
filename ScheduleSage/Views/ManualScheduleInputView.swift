//
//  ManualScheduleInputView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/**
 手动输入日程页
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
    var onEventsProcessed: ([CalendarEvent]) -> Void
    
    init(isPresented: Binding<Bool>, llmProcessor: LLMEventProcessor, onEventsProcessed: @escaping ([CalendarEvent]) -> Void) {
        self._isPresented = isPresented
        self.llmProcessor = llmProcessor
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
                    action: { Task { await processSchedule() } }
                )
            }
            .frame(width: 440, height: 360)
            .background(ScheduleDesignSystem.Colors.background)
            .toast(
                isPresented: $showToast,
                type: toastType,
                message: toastMessage
            )
            .navigationDestination(isPresented: $navigateToEventList) {
                EventListView(
                    proStatus: .free(remainingUses: 12),
                    events: processedEvents,
                    onUpgrade: {},
                    onAdd: { navigateToEventList = false },
                    onImport: {},
                    onBack: { navigateToEventList = false }
                )
            }
        }
    }
    
    private func processSchedule() async {
        guard !inputText.isEmpty else { return }
        isProcessing = true
        
        do {
            processedEvents = try await llmProcessor.processContent(inputText)
            onEventsProcessed(processedEvents)
            isPresented = false
        } catch {
            toastType = .error
            toastMessage = error.localizedDescription
            showToast = true
        }
        
        isProcessing = false
    }
}

// MARK: - Subviews
private struct HeaderView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: ScheduleDesignSystem.Spacing.iconSpacing) {
            Text(NSLocalizedString("manual_input_title", comment: ""))
                .font(ScheduleDesignSystem.Typography.headerTitle)
                .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
            Spacer()
            CloseButton(action: { isPresented = false })
        }
        .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
        .padding(.top, ScheduleDesignSystem.Layout.containerPadding.top)
        .padding(.bottom, ScheduleDesignSystem.Spacing.vertical)
    }
}

private struct InputArea: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .font(ScheduleDesignSystem.Typography.bodyRegular)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .background(placeholderView)
            .padding(ScheduleDesignSystem.Spacing.contentPadding)
            .background(ScheduleDesignSystem.Colors.lightGray)
            .cornerRadius(ScheduleDesignSystem.Dimensions.cardCornerRadius)
            .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
    }
    
    private var placeholderView: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty && !isFocused {
                Text(NSLocalizedString("schedule_input_placeholder", comment: ""))
                    .font(ScheduleDesignSystem.Typography.bodyRegular)
                    .foregroundColor(ScheduleDesignSystem.Colors.tertiaryText)
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
                        .tint(ScheduleDesignSystem.Colors.background)
                }
                Text(NSLocalizedString("recognize_button", comment: ""))
                    .font(ScheduleDesignSystem.Typography.buttonLabel)
                    .foregroundColor(ScheduleDesignSystem.Colors.background)
            }
            .frame(maxWidth: .infinity)
            .frame(height: ScheduleDesignSystem.Dimensions.buttonHeight)
            .background(ScheduleDesignSystem.Colors.primary)
            .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
        }
        .buttonStyle(.plain)
        .withHoverEffect(scale: 1.02, brightness: 0.05)
        .disabled(isDisabled)
        .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
        .padding(.bottom, ScheduleDesignSystem.Layout.containerPadding.bottom)
        .padding(.top, ScheduleDesignSystem.Spacing.vertical)
    }
}

private struct CloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .withHoverEffect()
    }
}

#if DEBUG
struct ManualScheduleInputView_Previews: PreviewProvider {
    static var previews: some View {
        ManualScheduleInputView(
            isPresented: .constant(true),
            llmProcessor: PreviewData.mockLLMProcessor
        ) { _ in }
    }
}
#endif 

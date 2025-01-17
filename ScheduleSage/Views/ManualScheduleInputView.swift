//
//  ManualScheduleInputView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import SwiftUI

/**
 手动输入日程页面
 */
struct ManualScheduleInputView: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var isPresented: Bool
  @State private var inputText: String = ""
  @State private var isProcessing: Bool = false
  @State private var showError: Bool = false
  @State private var errorMessage: String = ""
  @State private var navigateToEventList: Bool = false
  @State private var processedEvents: [CalendarEvent] = []
  
  @FocusState private var isFocused: Bool
  
  private let llmProcessor: LLMEventProcessor
  
  init(
    isPresented: Binding<Bool>,
    llmProcessor: LLMEventProcessor
  ) {
    self._isPresented = isPresented
    self.llmProcessor = llmProcessor
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack(spacing: ScheduleDesignSystem.Spacing.iconSpacing) {
        Text(NSLocalizedString("manual_input_title", comment: ""))
          .font(ScheduleDesignSystem.Typography.headerTitle)
          .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
        
        Spacer()
        
        Button(action: { isPresented = false }) {
          Image(systemName: "xmark")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(ScheduleDesignSystem.Colors.secondaryGray)
            .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .withHoverEffect()
      }
      .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
      .padding(.top, ScheduleDesignSystem.Layout.containerPadding.top)
      .padding(.bottom, ScheduleDesignSystem.Spacing.vertical)
      
      // Input Area
      TextEditor(text: $inputText)
        .font(ScheduleDesignSystem.Typography.bodyRegular)
        .focused($isFocused)
        .scrollContentBackground(.hidden)
        .background(
          ZStack(alignment: .topLeading) {
            if inputText.isEmpty && !isFocused {
              Text(NSLocalizedString("schedule_input_placeholder", comment: ""))
                .font(ScheduleDesignSystem.Typography.bodyRegular)
                .foregroundColor(ScheduleDesignSystem.Colors.tertiaryText)
                .padding(.top, 8)
                .padding(.leading, 5)
            }
          }
        )
        .padding(ScheduleDesignSystem.Spacing.contentPadding)
        .background(ScheduleDesignSystem.Colors.lightGray)
        .cornerRadius(ScheduleDesignSystem.Dimensions.cardCornerRadius)
        .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
      
      Spacer()
      
      // Recognize Button
      Button(action: {
        Task {
          await processSchedule()
        }
      }) {            
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
      .disabled(isProcessing || inputText.isEmpty)
      .padding(.horizontal, ScheduleDesignSystem.Layout.containerPadding.leading)
      .padding(.bottom, ScheduleDesignSystem.Layout.containerPadding.bottom)
      .padding(.top, ScheduleDesignSystem.Spacing.vertical)
    }
    .frame(width: 440, height: 360)
    .background(ScheduleDesignSystem.Colors.background)
    .alert(NSLocalizedString("error_title", comment: ""), isPresented: $showError) {
      Button(NSLocalizedString("ok_button", comment: "")) {
        showError = false
      }
    } message: {
      Text(errorMessage)
    }
    .navigationDestination(isPresented: $navigateToEventList) {
      EventListView(
        proStatus: .free(remainingUses: 12), // 这里应该从实际的 ViewModel 获取
        events: processedEvents,
        onUpgrade: {},
        onAdd: { navigateToEventList = false },
        onImport: {},
        onBack: { navigateToEventList = false }
      )
    }
  }
  
  private func processSchedule() async {
    guard !inputText.isEmpty else { return }
    
    isProcessing = true
    do {
      processedEvents = try await llmProcessor.processContent(inputText)
      navigateToEventList = true
    } catch {
      errorMessage = error.localizedDescription
      showError = true
    }
    isProcessing = false
  }
}

#if DEBUG
struct ManualScheduleInputView_Previews: PreviewProvider {
  static var previews: some View {
    ManualScheduleInputView(
      isPresented: .constant(true),
      llmProcessor: PreviewData.mockLLMProcessor
    )
  }
}
#endif 

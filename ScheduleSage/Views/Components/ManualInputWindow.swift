//
//  ManualInputWindow.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import SwiftUI

struct ManualInputWindow: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManualInputViewModel()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("manual_input.window_title")
                    .font(ScheduleDesignSystem.Typography.headerTitle)
                    .foregroundColor(ScheduleDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ScheduleDesignSystem.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(ScheduleDesignSystem.Colors.background)
            
            // 内容区
            VStack(spacing: ScheduleDesignSystem.Spacing.vertical) {
                TextEditor(text: $inputText)
                    .font(ScheduleDesignSystem.Typography.bodyRegular)
                    .frame(height: 150)
                    .padding(8)
                    .focused($isInputFocused)
                    .background(
                        RoundedRectangle(cornerRadius: ScheduleDesignSystem.Dimensions.cardCornerRadius)
                            .stroke(ScheduleDesignSystem.Colors.borderGray, lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if inputText.isEmpty && !isInputFocused {
                                Text("manual_input.placeholder")
                                    .font(ScheduleDesignSystem.Typography.bodyRegular)
                                    .foregroundColor(ScheduleDesignSystem.Colors.tertiaryText)
                                    .padding(.leading, 12)
                                    .padding(.top, 12)
                            }
                        },
                        alignment: .topLeading
                    )
                    .onAppear {
                        isInputFocused = true
                    }
                
                // 识别按钮
                Button(action: {
                    Task {
                        await viewModel.recognizeText(inputText)
                    }
                }) {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        }
                        
                        Text("manual_input.recognize")
                            .font(ScheduleDesignSystem.Typography.buttonLabel)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: ScheduleDesignSystem.Dimensions.buttonHeight)
                    .background(ScheduleDesignSystem.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(ScheduleDesignSystem.Dimensions.buttonCornerRadius)
                }
                .disabled(viewModel.isProcessing || inputText.isEmpty)
                .opacity(viewModel.isProcessing || inputText.isEmpty ? 0.6 : 1.0)
            }
            .padding()
        }
        .frame(width: ScheduleDesignSystem.Dimensions.containerWidth * 0.8)
        .background(ScheduleDesignSystem.Colors.background)
        .toast(
            isPresented: $viewModel.showToast,
            type: viewModel.toastType,
            message: viewModel.toastMessage
        )
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: .mainWindowWillClose,
                object: nil,
                queue: .main
            ) { _ in
                dismiss()
            }
        }
    }
}

#Preview {
    ManualInputWindow()
        .frame(width: 400, height: 300)
        .background(ScheduleDesignSystem.Colors.background)
} 
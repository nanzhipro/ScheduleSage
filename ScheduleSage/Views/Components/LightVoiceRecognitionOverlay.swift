//
//  LightVoiceRecognitionOverlay.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-03.
//

import SwiftUI

/**
 轻量级语音识别覆盖视图
 
 提供非侵入式语音识别UI，实时显示语音录入状态和识别内容
 */
struct LightVoiceRecognitionOverlay: View {
    @ObservedObject var viewModel: AddScheduleViewModel
    
    // 动画状态
    @State private var waveAnimation = false
    @State private var waveScale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    
    private let micColor = Color.red
    
    var body: some View {
        VStack(spacing: 8) {
            // 顶部麦克风和状态指示
            HStack(spacing: 16) {
                // 麦克风图标和动画波浪
                ZStack {
                    // 声波动画
                    Circle()
                        .fill(micColor.opacity(0.2))
                        .frame(width: 42, height: 42)
                        .scaleEffect(waveScale)
                        .opacity(waveAnimation ? 0.3 : 0.8)
                    
                    // 中心麦克风图标
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(micColor)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                }
                .frame(width: 48, height: 48)
                
                // 状态文本
                Text(NSLocalizedString("正在录音...", comment: ""))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // 停止按钮
                Button {
                    viewModel.stopVoiceRecognition()
                    viewModel.showVoiceRecognitionView = false
                } label: {
                    Text(NSLocalizedString("完成", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.gray.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .withHoverEffect(scale: 1.05, brightness: 0.05)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.7))
            )
            .overlay(
                // 底部音量指示器
                Rectangle()
                    .fill(micColor)
                    .frame(height: 3)
                    .frame(width: CGFloat(viewModel.audioLevel) * 100)
                    .animation(.easeOut(duration: 0.1), value: viewModel.audioLevel)
                    .padding(.bottom, -1.5),
                alignment: .bottom
            )
        }
        .frame(width: 300)
        .padding(.vertical, 8)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // 开启持续波动动画
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            waveAnimation = true
            waveScale = 1.4
        }
    }
}

#if DEBUG
struct LightVoiceRecognitionOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
            LightVoiceRecognitionOverlay(
                viewModel: {
                    let vm = AddScheduleViewModel()
                    vm.isRecording = true
                    vm.audioLevel = 0.6
                    return vm
                }()
            )
        }
    }
}
#endif 
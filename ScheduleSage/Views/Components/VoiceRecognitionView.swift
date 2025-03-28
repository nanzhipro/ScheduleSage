//
//  VoiceRecognitionView.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-03.
//

import SwiftUI

/// 语音识别视图组件
public struct VoiceRecognitionView: View {
    // MARK: - 状态和环境
    @StateObject private var viewModel = VoiceRecognitionViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - 回调属性
    /// 识别完成回调
    public var onRecognitionCompleted: ((String) -> Void)?
    
    // MARK: - 视图构建
    public var body: some View {
        VStack(spacing: 20) {
            // 顶部标题栏
            HStack {
                Button {
                    viewModel.cancelRecognition()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(NSLocalizedString("voice_recognition_title", comment: "语音识别"))
                    .font(.headline)
                
                Spacer()
                
                if viewModel.canSubmit {
                    Button {
                        viewModel.submitRecognition { text in
                            onRecognitionCompleted?(text)
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        Text(NSLocalizedString("voice_recognition_done", comment: "完成"))
                            .fontWeight(.medium)
                    }
                } else {
                    Button {
                        // 占位按钮，保持布局对称
                    } label: {
                        Text(NSLocalizedString("voice_recognition_done", comment: "完成"))
                            .fontWeight(.medium)
                            .foregroundColor(.clear)
                    }
                    .disabled(true)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 状态显示
            statusView
            
            // 语音波形图和录制按钮
            waveformAndButtonView
            
            Spacer()
            
            // 底部提示
            footerView
        }
        .padding(.vertical)
        .background(DesignSystem.Colors.background)
        .onAppear {
            viewModel.requestMicrophoneAccess()
        }
    }
    
    // MARK: - 子视图
    
    /// 状态显示视图
    private var statusView: some View {
        VStack(spacing: 12) {
            switch viewModel.state {
            case .idle, .preparing:
                Text(NSLocalizedString("voice_recognition_preparing", comment: "准备开始录音..."))
                    .font(.title3)
                
            case .recording(let duration):
                VStack(spacing: 8) {
                    Text(NSLocalizedString("voice_recognition_listening", comment: "正在聆听..."))
                        .font(.title3)
                    
                    Text(timeString(from: duration))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
            case .processing:
                Text(NSLocalizedString("voice_recognition_processing", comment: "正在识别..."))
                    .font(.title3)
                
            case .success(let text):
                VStack(spacing: 8) {
                    Text(NSLocalizedString("voice_recognition_result", comment: "识别结果"))
                        .font(.headline)
                    
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
            case .failure(let error):
                VStack(spacing: 8) {
                    Text(NSLocalizedString("voice_recognition_failed", comment: "识别失败"))
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
        }
        .frame(height: 80)
    }
    
    /// 波形图和录制按钮视图
    private var waveformAndButtonView: some View {
        VStack(spacing: 40) {
            // 音频波形图
            AudioWaveformView(
                level: viewModel.audioLevel,
                isActive: viewModel.isRecording
            )
            .frame(height: 60)
            .padding(.horizontal, 40)
            
            // 录制按钮
            Button {
                viewModel.toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 70, height: 70)
                    
                    if viewModel.isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isProcessing)
        }
        .padding(.vertical, 20)
    }
    
    /// 底部提示视图
    private var footerView: some View {
        Text(NSLocalizedString("voice_recognition_max_duration", comment: "最长录制时间为60秒"))
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom)
    }
    
    // MARK: - 辅助方法
    
    /// 将时间间隔转换为格式化字符串
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 波形视图

/// 音频波形显示组件
private struct AudioWaveformView: View {
    // MARK: - 属性
    var level: Float
    var isActive: Bool
    private let barCount = 20
    
    // MARK: - 视图构建
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: 6, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
        .opacity(isActive ? 1.0 : 0.5)
    }
    
    // MARK: - 辅助方法
    
    /// 计算特定索引处的条形高度
    private func barHeight(for index: Int) -> CGFloat {
        guard isActive else { return 15 }
        
        // 确定中心位置
        let centerOffset = abs(Double(index) - Double(barCount) / 2.0)
        let normalizedCenter = 1.0 - min(centerOffset / Double(barCount / 2), 1.0)
        
        // 添加随机变化以模拟波形
        let randomComponent = Double.random(in: -0.2...0.2)
        
        // 基于音频电平和中心位置计算高度
        let height = 10 + 50 * Double(level) * (normalizedCenter + randomComponent)
        return max(CGFloat(height), 5)
    }
    
    /// 波形条的颜色
    private var barColor: Color {
        isActive ? .accentColor : .gray
    }
}

// MARK: - ViewModel

/// 语音识别视图模型
class VoiceRecognitionViewModel: ObservableObject {
    // MARK: - 发布属性
    @Published var state: VoiceRecognitionState = .idle
    @Published var audioLevel: Float = 0.0
    
    // MARK: - 计算属性
    var isRecording: Bool {
        if case .recording = state {
            return true
        }
        return false
    }
    
    var isProcessing: Bool {
        if case .processing = state {
            return true
        }
        return false
    }
    
    var canSubmit: Bool {
        if case .success = state {
            return true
        }
        return false
    }
    
    // MARK: - 私有属性
    private var voiceService: VoiceRecognitionServiceProtocol
    
    // MARK: - 初始化
    init(voiceService: VoiceRecognitionServiceProtocol = VoiceRecognitionService()) {
        self.voiceService = voiceService
        
        // 设置回调
        self.voiceService.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.state = state
            }
        }
        
        self.voiceService.onLevelChanged = { [weak self] level in
            DispatchQueue.main.async {
                self?.audioLevel = level
            }
        }
    }
    
    // MARK: - 公开方法
    
    /// 请求麦克风权限
    func requestMicrophoneAccess() {
        voiceService.requestMicrophoneAccess { [weak self] _ in
            // 权限结果处理已在服务中完成
        }
    }
    
    /// 切换录制状态（开始/停止）
    func toggleRecording() {
        if isRecording {
            Task {
                do {
                    _ = try await voiceService.stopRecordingAndRecognize()
                } catch {
                    // 错误处理已在服务的状态回调中进行
                }
            }
        } else {
            voiceService.startRecording()
        }
    }
    
    /// 提交识别结果
    func submitRecognition(completion: @escaping (String) -> Void) {
        if case .success(let text) = state {
            completion(text)
        }
    }
    
    /// 取消识别
    func cancelRecognition() {
        voiceService.cancel()
    }
    
    /// 重置状态
    func resetState() {
        if let resetFunc = voiceService as? VoiceRecognitionService {
            resetFunc.resetState()
        } else {
            voiceService.cancel() // 备选方案，使用 cancel
        }
    }
}

// MARK: - 预览
struct VoiceRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceRecognitionView()
    }
} 
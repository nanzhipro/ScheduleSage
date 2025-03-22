//
//  AudioRecorder.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-17.
//

import Foundation
import AppKit
import AVFoundation

/// 音频录制服务，基于AVAudioEngine实现
public final class AudioRecorder: AudioRecorderProtocol {
    // MARK: - Public properties
    
    public private(set) var isRecording = false
    public var onErrorOccurred: ((Error) -> Void)?
    public var onLevelChanged: ((Float) -> Void)?
    
    // MARK: - Private properties
    
    private let audioEngine = AVAudioEngine()
    private var settings = AudioRecorderSettings()
    private var audioBuffer: AVAudioPCMBuffer?
    private var levelMonitorTimer: Timer?
    
    /// 日志服务
    private let logger = LoggerService.makeCompatible(category: "AudioRecorder")
    /// 音频录制分类标识符
    private let logCategory = "AudioRecorder"
    
    // MARK: - Initialization
    
    /// 初始化音频录制器
    public init() {
        logger.debug("Audio recorder initialized")
    }
    
    // MARK: - Public methods
    
    /// 请求麦克风访问权限
    /// - Parameter completion: 权限请求完成后的回调，参数表示是否获得权限
    public func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        logger.info("Requesting microphone access permission")
        
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.logger.info("Microphone permission result: \(granted ? "granted" : "denied")")
                completion(granted)
            }
        }
        #elseif os(macOS)
        if #available(macOS 10.14, *) {
            DispatchQueue.main.async {
                let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                self.logger.debug("Current microphone permission status: \(self.authStatusDescription(for: authStatus))")
                
                switch authStatus {
                case .authorized:
                    self.logger.info("Microphone access already authorized")
                    completion(true)
                case .denied, .restricted:
                    self.logger.warning("Microphone access denied or restricted")
                    self.showMicrophonePermissionAlert()
                    completion(false)
                case .notDetermined:
                    self.logger.info("Microphone permission not determined, requesting access")
                    self.requestMicrophonePermissionMacOS(completion: completion)
                @unknown default:
                    self.logger.warning("Unknown microphone permission status")
                    completion(false)
                }
            }
        } else {
            logger.info("Using older macOS version without runtime permissions, assuming granted")
            completion(true)
        }
        #endif
    }
    
    /// 配置音频录制参数
    /// - Parameter settings: 音频录制设置
    public func configure(with settings: AudioRecorderSettings) {
        guard !isRecording else {
            let error = AudioRecorderError.configurationWhileRecording
            logger.error("Cannot configure while recording: \(error.localizedDescription)")
            onErrorOccurred?(error)
            return
        }
        
        logger.debug("Configuring audio recorder with settings: \(settings)")
        self.settings = settings
    }
    
    /// 开始录制音频
    /// - Returns: 是否成功开始录制
    @discardableResult
    public func startRecording() -> Bool {
        guard !isRecording else {
            logger.warning("Recording already in progress, ignoring start request")
            return false
        }
        
        #if os(macOS)
        if #available(macOS 10.14, *), AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            let error = AudioRecorderError.microphonePermissionDenied
            logger.error("Cannot start recording - microphone permission not granted: \(error.localizedDescription)")
            onErrorOccurred?(error)
            return false
        }
        #endif
        
        do {
            logger.info("Starting audio recording")
            
            #if os(iOS)
            try configureAudioSessionForRecording()
            #elseif os(macOS)
            resetAudioEngineIfNeeded()
            #endif
            
            audioBuffer = nil
            let inputNode = audioEngine.inputNode
            let recordingFormat = createRecordingFormat()
            
            let bufferSize = AVAudioFrameCount(recordingFormat.sampleRate * 10) // 10秒缓冲区
            guard let buffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: bufferSize) else {
                throw AudioRecorderError.bufferCreationFailed
            }
            audioBuffer = buffer
            
            logger.debug("Installing audio tap with format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels")
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (pcmBuffer, _) in
                self?.processTapBuffer(pcmBuffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            
            if settings.enableLevelMonitoring {
                setupLevelMonitoring()
            }
            
            logger.info("Audio recording started successfully")
            return true
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            isRecording = false
            onErrorOccurred?(error)
            return false
        }
    }
    
    /// 停止录制音频
    /// - Returns: 录制完成的音频缓冲区，如果录制失败则返回nil
    @discardableResult
    public func stopRecording() -> AVAudioPCMBuffer? {
        guard isRecording else {
            logger.debug("No active recording to stop")
            return nil
        }
        
        logger.info("Stopping audio recording")
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        stopLevelMonitoring()
        isRecording = false
        
        #if os(iOS)
        deactivateAudioSession()
        #endif
        
        logger.debug("Audio recording stopped, buffer length: \(audioBuffer?.frameLength ?? 0) frames")
        return audioBuffer
    }
    
    /// 重置录音器状态
    public func reset() {
        logger.debug("Resetting audio recorder")
        if isRecording {
            stopRecording()
        }
        audioBuffer = nil
    }
    
    // MARK: - Private methods
    
    /// 处理音频采集缓冲区数据
    private func processTapBuffer(_ pcmBuffer: AVAudioPCMBuffer) {
        guard isRecording, let audioBuffer = self.audioBuffer else { return }
        
        // 将录制的音频附加到缓冲区
        let offset = AVAudioFramePosition(audioBuffer.frameLength)
        let remainingCapacity = audioBuffer.frameCapacity - audioBuffer.frameLength
        let copyLength = min(pcmBuffer.frameLength, remainingCapacity)
        
        if let destBuffer = audioBuffer.floatChannelData, let srcBuffer = pcmBuffer.floatChannelData {
            for channel in 0..<Int(audioBuffer.format.channelCount) {
                memcpy(
                    destBuffer[channel] + Int(offset),
                    srcBuffer[channel],
                    Int(copyLength) * MemoryLayout<Float>.size
                )
            }
            audioBuffer.frameLength += copyLength
        }
    }
    
    #if os(macOS)
    /// 显示麦克风权限提示对话框
    private func showMicrophonePermissionAlert() {
        logger.debug("Showing microphone permission alert")
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("microphone_restricted_title", comment: "麦克风访问受限")
        alert.informativeText = NSLocalizedString("microphone_restricted_message", comment: "ScheduleSage需要使用麦克风进行语音识别。请在系统设置中允许访问麦克风。")
        alert.addButton(withTitle: NSLocalizedString("open_system_settings", comment: "打开系统设置"))
        alert.addButton(withTitle: NSLocalizedString("cancel", comment: "取消"))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                logger.debug("Opening system preferences for microphone permissions")
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// 在macOS上请求麦克风权限
    private func requestMicrophonePermissionMacOS(completion: @escaping (Bool) -> Void) {
        logger.debug("Attempting to trigger permission request on macOS")
        
        // 尝试方法1: 强制触发权限请求
        forceTriggerPermissionPrompt()
        
        // 尝试方法2: 使用标准API
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            self.logger.debug("Standard API permission request result: \(granted ? "granted" : "denied")")
            
            DispatchQueue.main.async {
                if granted {
                    self.logger.info("Microphone permission granted")
                    completion(true)
                } else {
                    self.logger.debug("Standard request failed, trying method 3: actual device usage")
                    self.attemptDeviceAccessForPermission(completion: completion)
                }
            }
        }
    }
    
    /// 尝试直接使用设备来触发权限请求
    private func attemptDeviceAccessForPermission(completion: @escaping (Bool) -> Void) {
        guard let device = AVCaptureDevice.default(for: .audio) else {
            logger.warning("Failed to get microphone device")
            completion(false)
            return
        }
        
        logger.debug("Successfully retrieved microphone device: \(device.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            logger.debug("Successfully created device input")
            
            let tmpSession = AVCaptureSession()
            if tmpSession.canAddInput(input) {
                logger.debug("Adding microphone input to session")
                tmpSession.addInput(input)
                
                logger.debug("Starting capture session")
                tmpSession.startRunning()
                
                // 短暂运行后停止
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.logger.debug("Stopping capture session")
                    tmpSession.stopRunning()
                    
                    // 再次检查权限状态
                    let newStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                    self.logger.info("Final permission status: \(self.authStatusDescription(for: newStatus))")
                    completion(newStatus == .authorized)
                }
            } else {
                logger.warning("Cannot add microphone input to session")
                completion(false)
            }
        } catch {
            logger.error("Error creating device input: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    /// 强制触发麦克风权限请求
    private func forceTriggerPermissionPrompt() {
        logger.debug("Force triggering permission prompt")
        
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .audio) else {
            logger.warning("Cannot get microphone device")
            return
        }
        
        logger.debug("Found device: \(device.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            logger.debug("Successfully created device input")
            
            if session.canAddInput(input) {
                logger.debug("Adding device input to session")
                session.addInput(input)
            } else {
                logger.warning("Cannot add device input to session")
            }
            
            logger.debug("Starting capture session")
            session.startRunning()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.logger.debug("Stopping capture session")
                session.stopRunning()
                
                let status = AVCaptureDevice.authorizationStatus(for: .audio)
                self.logger.debug("Post-trigger permission status: \(self.authStatusDescription(for: status))")
            }
        } catch {
            logger.error("Failed to create device input: \(error.localizedDescription)")
        }
    }
    
    /// 如果需要，重置音频引擎
    private func resetAudioEngineIfNeeded() {
        if audioEngine.isRunning {
            logger.debug("Resetting running audio engine")
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    #endif
    
    #if os(iOS)
    /// 配置iOS音频会话
    private func configureAudioSessionForRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        logger.debug("Configuring iOS audio session for recording")
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    /// 停用iOS音频会话
    private func deactivateAudioSession() {
        do {
            logger.debug("Deactivating iOS audio session")
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.warning("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    #endif
    
    /// 创建录制格式
    private func createRecordingFormat() -> AVAudioFormat {
        return AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: settings.sampleRate,
            channels: AVAudioChannelCount(settings.channels),
            interleaved: false
        )!
    }
    
    /// 设置音频电平监测
    private func setupLevelMonitoring() {
        stopLevelMonitoring()
        logger.debug("Setting up audio level monitoring")
        levelMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }
    
    /// 停止音频电平监测
    private func stopLevelMonitoring() {
        if levelMonitorTimer != nil {
            logger.debug("Stopping audio level monitoring")
            levelMonitorTimer?.invalidate()
            levelMonitorTimer = nil
        }
    }
    
    /// 更新音频电平
    private func updateAudioLevel() {
        guard isRecording, let onLevelChanged = onLevelChanged else { return }
        
        var peakPower: Float = 0.0
        
        if audioEngine.isRunning {
            let nodeVolume = audioEngine.inputNode.volume
            // 调整以模拟真实电平变化
            peakPower = nodeVolume * 0.8 + Float.random(in: 0...0.1)
        } else {
            peakPower = 0.01
        }
        
        // 归一化音频电平值（0.0-1.0）
        let normalizedLevel = min(1.0, peakPower * 5.0)
        
        DispatchQueue.main.async {
            onLevelChanged(normalizedLevel)
        }
    }
    
    /// 将授权状态转换为描述文本
    private func authStatusDescription(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "not determined"
        @unknown default: return "unknown"
        }
    }
}

// MARK: - 错误类型

/// 音频录制器可能产生的错误
public enum AudioRecorderError: Error {
    /// 在录制过程中尝试修改配置
    case configurationWhileRecording
    /// 创建音频缓冲区失败
    case bufferCreationFailed
    /// 音频引擎启动失败
    case audioEngineStartFailed
    /// 麦克风权限被拒绝
    case microphonePermissionDenied
}

// 扩展错误类型，添加本地化描述
extension AudioRecorderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configurationWhileRecording:
            return NSLocalizedString("audio_recorder_config_while_recording", comment: "不能在录制过程中修改设置")
        case .bufferCreationFailed:
            return NSLocalizedString("audio_recorder_buffer_creation_failed", comment: "无法创建音频缓冲区")
        case .audioEngineStartFailed:
            return NSLocalizedString("audio_recorder_engine_start_failed", comment: "音频引擎启动失败")
        case .microphonePermissionDenied:
            return NSLocalizedString("audio_recorder_permission_denied", comment: "麦克风权限被拒绝，请在系统设置中允许访问麦克风")
        }
    }
}

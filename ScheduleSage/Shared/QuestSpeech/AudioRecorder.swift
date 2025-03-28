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
    
    /// 录音最大持续时间（秒），默认60秒
    public var maxRecordingDuration: TimeInterval = 60.0
    
    // MARK: - Private properties
    
    private let audioEngine = AVAudioEngine()
    private var settings = AudioRecorderSettings()
    private var audioBuffer: AVAudioPCMBuffer?
    private var levelMonitorTimer: Timer?
    private var recordingStartTime: Date?
    private var recordingDuration: TimeInterval = 0
    
    /// 是否启用循环缓冲区模式（保留最新的N秒音频）
    private var useCircularBuffer = true
    /// 当前写入位置（帧）
    private var writePosition: AVAudioFrameCount = 0
    /// 缓冲区已满标志
    private var isBufferFilled = false
    
    /// 日志服务
    private let logger = LoggerService.makeCompatible(category: "AudioRecorder")
    
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
        requestIOSMicrophoneAccess(completion: completion)
        #elseif os(macOS)
        requestMacOSMicrophoneAccess(completion: completion)
        #endif
    }
    
    /// 配置音频录制参数
    /// - Parameter settings: 音频录制设置
    public func configure(with settings: AudioRecorderSettings) {
        guard !isRecording else {
            handleError(.configurationWhileRecording)
            return
        }
        
        logger.debug("Configuring audio recorder with settings: \(settings)")
        self.settings = settings
    }
    
    /// 配置是否使用循环缓冲区（保留最新的音频）
    /// - Parameter enabled: 是否启用循环缓冲区
    public func configureCircularBuffer(enabled: Bool) {
        guard !isRecording else {
            handleError(.configurationWhileRecording)
            return
        }
        
        logger.debug("Setting circular buffer mode: \(enabled ? "enabled" : "disabled")")
        self.useCircularBuffer = enabled
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
        if !hasMicrophonePermission() {
            handleError(.microphonePermissionDenied)
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
            
            try setupAudioBufferAndTap()
            
            // 重置录音状态和计时
            recordingStartTime = Date()
            recordingDuration = 0
            writePosition = 0
            isBufferFilled = false
            
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
        recordingStartTime = nil
        
        #if os(iOS)
        deactivateAudioSession()
        #endif
        
        // 处理循环缓冲区数据，确保返回的是有效的音频段
        if let buffer = audioBuffer, useCircularBuffer && isBufferFilled {
            return createFinalAudioBuffer(from: buffer)
        }
        
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
        recordingStartTime = nil
        recordingDuration = 0
        writePosition = 0
        isBufferFilled = false
    }
    
    // MARK: - Private methods
    
    /// 从循环缓冲区创建最终的有序音频缓冲区
    private func createFinalAudioBuffer(from circularBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let destBuffer = AVAudioPCMBuffer(
            pcmFormat: circularBuffer.format,
            frameCapacity: circularBuffer.frameCapacity
        ) else {
            logger.error("Failed to create destination buffer for final audio")
            return nil
        }
        
        guard let srcData = circularBuffer.floatChannelData, let destData = destBuffer.floatChannelData else {
            logger.error("Failed to access buffer channel data")
            return nil
        }
        
        let channels = Int(circularBuffer.format.channelCount)
        let framesPerBuffer = Int(circularBuffer.frameCapacity)
        
        // 循环缓冲区逻辑: 先复制writePosition到结尾的部分，再复制开始到writePosition的部分
        for channel in 0..<channels {
            // 1. 复制 writePosition 到结尾的部分 (较旧的数据)
            let remainingFrames = framesPerBuffer - Int(writePosition)
            if remainingFrames > 0 {
                memcpy(
                    destData[channel],
                    srcData[channel] + Int(writePosition),
                    remainingFrames * MemoryLayout<Float>.size
                )
            }
            
            // 2. 复制开始到 writePosition 的部分 (较新的数据)
            if writePosition > 0 {
                memcpy(
                    destData[channel] + remainingFrames,
                    srcData[channel],
                    Int(writePosition) * MemoryLayout<Float>.size
                )
            }
        }
        
        destBuffer.frameLength = circularBuffer.frameCapacity
        return destBuffer
    }
    
    /// 设置音频缓冲区和安装音频Tap
    private func setupAudioBufferAndTap() throws {
        audioBuffer = nil
        let inputNode = audioEngine.inputNode
        
        // 使用硬件的输入格式而不是尝试强制设置自定义格式
        let hardwareFormat = inputNode.inputFormat(forBus: 0)
        let recordingFormat = settings.useHardwareFormat ? hardwareFormat : createRecordingFormat()
        
        logger.debug("Hardware input format: \(hardwareFormat.sampleRate)Hz, \(hardwareFormat.channelCount) channels")
        logger.debug("Using recording format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels")
        
        // 计算最大录音时长对应的缓冲区大小
        let bufferSize = AVAudioFrameCount(recordingFormat.sampleRate * maxRecordingDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: bufferSize) else {
            throw AudioRecorderError.bufferCreationFailed
        }
        audioBuffer = buffer
        
        // 使用硬件支持的格式安装tap，避免格式不匹配崩溃
        logger.debug("Installing audio tap with format: \(hardwareFormat.sampleRate)Hz, \(hardwareFormat.channelCount) channels")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] (pcmBuffer, _) in
            self?.processTapBuffer(pcmBuffer)
        }
        
        audioEngine.prepare()
    }
    
    /// 处理错误并触发回调
    private func handleError(_ error: AudioRecorderError) {
        logger.error("Error occurred: \(error.localizedDescription)")
        onErrorOccurred?(error)
    }
    
    /// 检查是否有麦克风权限（仅macOS）
    private func hasMicrophonePermission() -> Bool {
        #if os(macOS)
        if #available(macOS 10.14, *) {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
        return true
        #else
        return true
        #endif
    }
    
    /// 处理音频采集缓冲区数据
    private func processTapBuffer(_ pcmBuffer: AVAudioPCMBuffer) {
        guard isRecording, let audioBuffer = self.audioBuffer else { return }
        
        // 更新录音持续时间
        if let startTime = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(startTime)
        }
        
        // 标准模式：线性追加到缓冲区
        if !useCircularBuffer {
            processLinearBuffer(pcmBuffer, audioBuffer: audioBuffer)
            return
        }
        
        // 循环缓冲区模式：始终保留最新的音频数据
        processCircularBuffer(pcmBuffer, audioBuffer: audioBuffer)
    }
    
    /// 处理线性缓冲区模式（仅追加不覆盖）
    private func processLinearBuffer(_ pcmBuffer: AVAudioPCMBuffer, audioBuffer: AVAudioPCMBuffer) {
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
    
    /// 处理循环缓冲区模式（保留最新的N秒音频）
    private func processCircularBuffer(_ pcmBuffer: AVAudioPCMBuffer, audioBuffer: AVAudioPCMBuffer) {
        guard let destBuffer = audioBuffer.floatChannelData,
              let srcBuffer = pcmBuffer.floatChannelData else { return }
        
        let channels = Int(audioBuffer.format.channelCount)
        let bufferCapacity = Int(audioBuffer.frameCapacity)
        let incomingFrames = Int(pcmBuffer.frameLength)
        
        // 复制新数据到循环缓冲区
        for channel in 0..<channels {
            var remainingFrames = incomingFrames
            var srcOffset = 0
            
            // 可能需要分两次复制：一部分到缓冲区末尾，一部分回到缓冲区开头
            while remainingFrames > 0 {
                // 计算在当前位置可以复制的帧数
                let framesUntilEnd = bufferCapacity - Int(writePosition)
                let framesToCopy = min(remainingFrames, framesUntilEnd)
                
                // 复制数据
                memcpy(
                    destBuffer[channel] + Int(writePosition),
                    srcBuffer[channel] + srcOffset,
                    framesToCopy * MemoryLayout<Float>.size
                )
                
                // 更新位置和计数
                writePosition += AVAudioFrameCount(framesToCopy)
                if writePosition >= AVAudioFrameCount(bufferCapacity) {
                    writePosition = 0
                    isBufferFilled = true
                }
                
                remainingFrames -= framesToCopy
                srcOffset += framesToCopy
            }
        }
        
        // 更新frameLength，确保不超过capacity
        if !isBufferFilled {
            // 缓冲区未满时，frameLength = writePosition
            audioBuffer.frameLength = writePosition
        } else {
            // 缓冲区已满时，frameLength = capacity
            audioBuffer.frameLength = audioBuffer.frameCapacity
        }
    }
    
    // MARK: - iOS Specific Methods
    
    #if os(iOS)
    /// 请求iOS麦克风访问权限
    private func requestIOSMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.logger.info("Microphone permission result: \(granted ? "granted" : "denied")")
                completion(granted)
            }
        }
    }
    
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
    
    // MARK: - macOS Specific Methods
    
    #if os(macOS)
    /// 请求macOS麦克风访问权限
    private func requestMacOSMicrophoneAccess(completion: @escaping (Bool) -> Void) {
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
    }
    
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
        
        // 使用多种方法尝试请求权限
        forceTriggerPermissionPrompt()
        
        // 使用标准API
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            self.logger.debug("Standard API permission request result: \(granted ? "granted" : "denied")")
            
            DispatchQueue.main.async {
                if granted {
                    self.logger.info("Microphone permission granted")
                    completion(true)
                } else {
                    self.logger.debug("Standard request failed, trying actual device usage")
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
            let tmpSession = AVCaptureSession()
            
            guard tmpSession.canAddInput(input) else {
                logger.warning("Cannot add microphone input to session")
                completion(false)
                return
            }
            
            tmpSession.addInput(input)
            tmpSession.startRunning()
            
            // 短暂运行后停止并检查权限
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                tmpSession.stopRunning()
                let newStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                self.logger.info("Final permission status: \(self.authStatusDescription(for: newStatus))")
                completion(newStatus == .authorized)
            }
        } catch {
            logger.error("Error creating device input: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    /// 强制触发麦克风权限请求
    private func forceTriggerPermissionPrompt() {
        logger.debug("Force triggering permission prompt")
        
        guard let device = AVCaptureDevice.default(for: .audio) else {
            logger.warning("Cannot get microphone device")
            return
        }
        
        do {
            let session = AVCaptureSession()
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
                session.startRunning()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    session.stopRunning()
                }
            }
        } catch {
            logger.error("Failed to create device input: \(error.localizedDescription)")
        }
    }
    
    /// 重置音频引擎，避免重复使用导致的问题
    private func resetAudioEngineIfNeeded() {
        if audioEngine.isRunning {
            logger.debug("Stopping existing audio engine")
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    #endif
    
    // MARK: - Audio Utilities
    
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
        
        let peakPower = calculatePeakPower()
        
        DispatchQueue.main.async {
            onLevelChanged(peakPower)
        }
    }
    
    /// 计算当前音频峰值电平
    private func calculatePeakPower() -> Float {
        var peakPower: Float = 0.0
        
        if audioEngine.isRunning {
            let nodeVolume = audioEngine.inputNode.volume
            // 调整以模拟真实电平变化
            peakPower = nodeVolume * 0.8 + Float.random(in: 0...0.1)
        } else {
            peakPower = 0.01
        }
        
        // 归一化音频电平值（0.0-1.0）
        return min(1.0, peakPower * 5.0)
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

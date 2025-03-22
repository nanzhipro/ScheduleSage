//
//  SpeechRecognizer.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-17.
//

import Foundation
import AppKit
import Speech
import AVFoundation

/// 语音识别服务，基于Apple Speech框架实现
public final class SpeechRecognizer: NSObject, SpeechRecognizerProtocol, SFSpeechRecognizerDelegate {
    // MARK: - Public properties
    
    public private(set) var isRecognizing = false
    public private(set) var currentLocale: Locale
    public var requiresOnDeviceRecognition = false
    
    public var supportedLocales: [Locale] {
        return SFSpeechRecognizer.supportedLocales().sorted { $0.identifier < $1.identifier }
    }
    
    public var onTranscriptionUpdated: ((String) -> Void)?
    public var onRecognitionFinished: ((String?, Error?) -> Void)?
    
    // MARK: - Private properties
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var latestTranscription: String = ""
    
    /// 日志服务
    private let logger = LoggerService.makeCompatible(category: "SpeechRecognizer")
    /// 日志分类标识符
    private let logCategory = "SpeechRecognizer"
    
    // MARK: - Initialization
    
    /// 初始化语音识别器
    /// - Parameter locale: 初始语言设置，默认为设备当前语言
    public init(locale: Locale = .current) {
        self.currentLocale = locale
        super.init()
        setupSpeechRecognizer()
    }
    
    // MARK: - Public methods
    
    /// 检查语音识别服务是否可用
    /// - Returns: 服务可用状态
    public func isServiceAvailable() -> Bool {
        guard let recognizer = speechRecognizer else { 
            logger.debug("Speech recognizer not initialized")
            return false 
        }
        
        #if os(macOS)
        // macOS下需要检查Siri是否启用
        let isSiriEnabled = PlatformCompatibility.isSiriEnabled()
        let isAvailable = recognizer.isAvailable && isSiriEnabled
        logger.debug("Service availability check: recognizer=\(recognizer.isAvailable), Siri=\(isSiriEnabled)")
        return isAvailable
        #else
        // iOS下直接检查识别器可用性
        return recognizer.isAvailable
        #endif
    }
    
    /// 请求语音识别权限
    /// - Parameter completion: 权限请求完成后的回调，参数表示是否获得权限
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        logger.info("Requesting speech recognition authorization")
        SFSpeechRecognizer.requestAuthorization { status in
            self.logger.debug("Speech recognition authorization status: \(self.authStatusDescription(for: status))")
            DispatchQueue.main.async {
                if status == .denied || status == .restricted {
                    self.logger.warning("Speech recognition access denied or restricted")
                    self.showSpeechRecognitionPermissionAlert()
                }
                
                completion(status == .authorized)
            }
        }
    }
    
    /// 设置语音识别的语言区域
    /// - Parameter locale: 要使用的语言区域
    /// - Returns: 设置是否成功
    @discardableResult
    public func setLocale(_ locale: Locale) -> Bool {
        guard !isRecognizing, SFSpeechRecognizer.supportedLocales().contains(locale) else {
            logger.warning("Cannot change locale: recognition in progress or locale not supported")
            return false
        }
        
        logger.info("Changing recognition locale to \(locale.identifier)")
        currentLocale = locale
        setupSpeechRecognizer()
        return true
    }
    
    /// 从音频缓冲区开始语音识别
    /// - Parameter buffer: 包含音频数据的缓冲区
    /// - Returns: 识别是否成功启动
    @discardableResult
    public func startRecognition(from buffer: AVAudioPCMBuffer) -> Bool {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            logger.error("Cannot start recognition from buffer - recognizer not available")
            return false
        }
        
        logger.info("Starting recognition from audio buffer")
        
        // 停止任何进行中的识别
        stopRecognition()
        
        do {
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = requiresOnDeviceRecognition
            request.append(buffer)
            recognitionRequest = request
            
            isRecognizing = true
            latestTranscription = ""
            
            logger.debug("Creating recognition task for buffer")
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    self.handleRecognitionResult(result)
                }
                
                if error != nil || result?.isFinal == true {
                    self.finalizeRecognition(error: error)
                }
            }
            
            return true
        } catch {
            logger.error("Failed to start recognition from buffer: \(error.localizedDescription)")
            finalizeRecognition(error: error)
            return false
        }
    }
    
    /// 开始实时语音识别
    /// - Returns: 识别是否成功启动
    @discardableResult
    public func startLiveRecognition() -> Bool {
        logger.info("Starting live speech recognition")
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            logger.error("Cannot start live recognition - recognizer not available")
            return false
        }
        
        // 检查平台特定错误
        if let platformError = PlatformCompatibility.getPlatformSpecificError() {
            logger.error("Platform-specific error preventing recognition: \(platformError.localizedDescription)")
            finalizeRecognition(error: platformError)
            return false
        }
        
        // 停止任何进行中的识别
        stopRecognition()
        
        // 完全重置音频引擎状态，防止之前的状态影响
        logger.debug("Resetting audio engine state")
        audioEngine.stop()
        audioEngine.reset()
        
        #if os(iOS)
        do {
            logger.debug("Configuring iOS audio session for recognition")
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
            finalizeRecognition(error: error)
            return false
        }
        #endif
        
        do {
            // 创建实时识别请求
            logger.debug("Creating speech recognition request")
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = requiresOnDeviceRecognition
            recognitionRequest = request
            
            // 设置音频输入
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            logger.debug("Audio format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels")
            
            // 检查是否已有采集点，如果有则移除
            logger.debug("Installing audio tap for recognition")
            if audioEngine.isRunning {
                inputNode.removeTap(onBus: 0)
            }
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
                self?.processAudioBuffer(buffer)
            }
            
            // 启动音频引擎
            logger.debug("Preparing and starting audio engine")
            audioEngine.prepare()
            try audioEngine.start()
            
            // 开始识别任务
            logger.info("Starting speech recognition task")
            isRecognizing = true
            latestTranscription = ""
            
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.logger.warning("Recognition error: \(error.localizedDescription)")
                    self.handleRecognitionError(error)
                }
                
                if let result = result {
                    self.handleRecognitionResult(result)
                }
                
                if error != nil || result?.isFinal == true {
                    self.finalizeRecognition(error: error)
                }
            }
            
            logger.info("Speech recognition started successfully")
            return true
        } catch {
            logger.error("Failed to start live recognition: \(error.localizedDescription)")
            finalizeRecognition(error: error)
            return false
        }
    }
    
    /// 停止语音识别
    public func stopRecognition() {
        logger.info("Stopping speech recognition")
        
        // 停止音频引擎
        if audioEngine.isRunning {
            logger.debug("Stopping audio engine")
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        
        // 停止识别请求和任务
        logger.debug("Ending recognition request")
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // 重置状态
        recognitionRequest = nil
        recognitionTask = nil
        
        // 如果正在识别，通知完成
        if isRecognizing {
            logger.debug("Recognition ended, final text length: \(latestTranscription.count) characters")
            isRecognizing = false
            DispatchQueue.main.async {
                self.onRecognitionFinished?(self.latestTranscription, nil)
            }
        }
    }
    
    // MARK: - SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        logger.info("Speech recognizer availability changed: \(available ? "available" : "unavailable")")
        
        if !available && isRecognizing {
            logger.warning("Recognizer became unavailable while in use, stopping recognition")
            stopRecognition()
            
            let error = SpeechRecognizerError.serviceUnavailable
            DispatchQueue.main.async {
                self.onRecognitionFinished?(nil, error)
            }
        }
    }
    
    // MARK: - Private methods
    
    /// 处理音频缓冲区数据
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isRecognizing else { return }
        
        recognitionRequest?.append(buffer)
        
        // 音频电平检查（可选，仅用于日志）
        if buffer.frameLength > 0, let channelData = buffer.floatChannelData {
            var sum: Float = 0.0
            let channelCount = Int(buffer.format.channelCount)
            let frameLength = Int(buffer.frameLength)
            
            for ch in 0..<channelCount {
                for i in 0..<frameLength {
                    let sample = channelData[ch][i]
                    sum += sample * sample
                }
            }
            
            let rms = sqrt(sum / Float(frameLength * channelCount))
            if rms > 0.01 {  // 只在有实际声音时记录
                logger.debug("Audio input detected, level: \(rms)")
            }
        }
    }
    
    /// 处理识别结果
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult) {
        latestTranscription = result.bestTranscription.formattedString
        
        if !latestTranscription.isEmpty {
            logger.debug("Recognition result updated: \"\(latestTranscription.prefix(50))...\"")
        }
        
        DispatchQueue.main.async {
            self.onTranscriptionUpdated?(self.latestTranscription)
        }
    }
    
    /// 处理识别错误
    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        
        // 检查是否是超时或无语音输入错误
        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
            logger.warning("Local speech recognition service error")
            // 这里可以添加错误恢复策略，比如重试或故障切换
        }
    }
    
    /// 初始化语音识别器
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: currentLocale)
        speechRecognizer?.delegate = self
        
        let isAvailable = speechRecognizer?.isAvailable ?? false
        logger.debug("Initializing recognizer with locale: \(currentLocale.identifier), available: \(isAvailable)")
    }
    
    /// 显示语音识别权限提示对话框
    private func showSpeechRecognitionPermissionAlert() {
        logger.debug("Showing speech recognition permission alert")
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("speech_recognition_restricted_title", comment: "语音识别访问受限")
        alert.informativeText = NSLocalizedString("speech_recognition_restricted_message", comment: "ScheduleSage需要使用语音识别功能。请在系统设置中允许访问语音识别。")
        alert.addButton(withTitle: NSLocalizedString("open_system_settings", comment: "打开系统设置"))
        alert.addButton(withTitle: NSLocalizedString("cancel", comment: "取消"))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            logger.debug("Opening system preferences for speech recognition permissions")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// 结束识别过程
    private func finalizeRecognition(error: Error?) {
        let finalText = latestTranscription
        
        if let error = error {
            logger.error("Recognition terminated with error: \(error.localizedDescription)")
            
            // 检查常见的语音识别错误类型
            let nsError = error as NSError
            logger.debug("Error domain: \(nsError.domain), code: \(nsError.code)")
            
            // 处理特定错误类型
            if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
                logger.warning("Local speech recognition service error detected")
            } else if nsError.domain == "NSOSStatusErrorDomain" {
                logger.warning("Audio system error detected, code: \(nsError.code)")
            }
        } else if !finalText.isEmpty {
            logger.info("Recognition completed successfully with text: \"\(finalText.prefix(50))...\"")
        } else {
            logger.info("Recognition completed with no text result")
        }
        
        // 确保停止所有识别相关活动
        stopRecognition()
        
        // 重置音频引擎状态，确保清理干净
        if audioEngine.isRunning {
            logger.debug("Force stopping and resetting audio engine")
            audioEngine.stop()
            audioEngine.reset()
        }
        
        DispatchQueue.main.async {
            self.onRecognitionFinished?(finalText, error)
        }
    }
    
    /// 将授权状态转换为描述文本
    private func authStatusDescription(for status: SFSpeechRecognizerAuthorizationStatus) -> String {
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

/// 语音识别器可能产生的错误
public enum SpeechRecognizerError: Error {
    /// 语音识别服务不可用
    case serviceUnavailable
    /// 未获得语音识别权限
    case notAuthorized
    /// 不支持的语言区域
    case unsupportedLocale
    /// macOS上需要启用Siri
    case siriNotEnabled
}

// 扩展错误类型，添加本地化描述
extension SpeechRecognizerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return NSLocalizedString("speech_recognition_unavailable", comment: "语音识别服务当前不可用")
        case .notAuthorized:
            return NSLocalizedString("speech_recognition_not_authorized", comment: "未获得语音识别权限")
        case .unsupportedLocale:
            return NSLocalizedString("speech_recognition_unsupported_locale", comment: "不支持当前选择的语言")
        case .siriNotEnabled:
            return NSLocalizedString("speech_recognition_siri_disabled", comment: "请在系统偏好设置中启用Siri以使用语音识别功能")
        }
    }
}

// MARK: - 平台兼容性

/// 处理跨平台兼容性的工具类
private enum PlatformCompatibility {
    /// 检查Siri是否启用（macOS特有）
    static func isSiriEnabled() -> Bool {
        #if os(macOS)
        if #available(macOS 10.15, *) {
            // macOS 10.15+中，我们可以通过NSSpeechRecognizer检查Siri状态
            return NSSpeechRecognizer() != nil
        } else {
            // 旧版macOS中，我们无法可靠地检测，假设可用
            return true
        }
        #else
        return true
        #endif
    }
    
    /// 获取平台特定的错误信息
    static func getPlatformSpecificError() -> Error? {
        #if os(macOS)
        if !isSiriEnabled() {
            return SpeechRecognizerError.siriNotEnabled
        }
        #endif
        return nil
    }
}

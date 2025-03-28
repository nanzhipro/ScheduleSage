//
//  VoiceRecognitionService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-03.
//

import Foundation
import AVFoundation
import Alamofire

/// 语音识别服务实现
public final class VoiceRecognitionService: VoiceRecognitionServiceProtocol {
    // MARK: - Public properties
    public private(set) var state: VoiceRecognitionState = .idle {
        didSet {
            if oldValue != state {
                DispatchQueue.main.async {
                    self.onStateChanged?(self.state)
                }
            }
        }
    }
    
    public var onStateChanged: ((VoiceRecognitionState) -> Void)?
    public var onLevelChanged: ((Float) -> Void)?
    
    // MARK: - Private properties
    /// 音频录制服务
    private var audioRecorder: AudioRecordingService
    
    /// 日志记录器
    private let logger: LoggerService
    
    /// 录制开始时间
    private var recordingStartTime: Date?
    
    /// 录制计时器
    private var recordingTimer: Timer?
    
    /// 录制时长限制（秒）
    private let recordingDuration: TimeInterval = 60
    
    // MARK: - Initialization
    
    /// 初始化语音识别服务
    /// - Parameters:
    ///   - audioRecorder: 音频录制服务，默认使用标准实现
    ///   - logger: 日志记录器，默认使用标准实现
    public init(
        audioRecorder: AudioRecordingService = AudioRecorder(),
        logger: LoggerService = .makeCompatible(category: "VoiceRecognitionService")
    ) {
        self.audioRecorder = audioRecorder
        self.logger = logger
    }
    
    // MARK: - Public methods
    
    /// 请求麦克风访问权限
    /// - Parameter completion: 权限请求完成后的回调，参数表示是否获得权限
    public func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        logger.info("Requesting microphone access permission")
        // 使用 AudioRecorder 的权限状态
        completion(audioRecorder.hasMicrophonePermission)
    }
    
    /// 开始语音录制
    /// - Returns: 是否成功开始录制
    @discardableResult
    public func startRecording() -> Bool {
        logger.info("Starting voice recording")
        
        // 状态检查
        guard case .idle = state else {
            logger.warning("Cannot start recording: current state \(state) does not allow new recording session")
            return false
        }
        
        state = .preparing
        
        // 开始录制
        if audioRecorder.startRecording() {
            recordingStartTime = Date()
            startRecordingTimer()
            state = .recording(0)
            logger.debug("Voice recording started successfully")
            return true
        } else {
            logger.error("Failed to start voice recording")
            state = .failure(VoiceRecognitionError.recordingFailed)
            return false
        }
    }
    
    /// 停止录制并进行识别
    /// - Returns: 识别结果文本
    /// - Throws: VoiceRecognitionError
    public func stopRecordingAndRecognize() async throws -> String {
        logger.info("Stopping recording and starting recognition")
        
        // 状态检查和重置
        guard case .recording = state else {
            logger.warning("Cannot stop recording: current state \(state) is not recording")
            
            // 确保状态重置为 idle
            if case .success = state {
                resetState()
            } else if case .failure = state {
                resetState()
            }
            
            throw VoiceRecognitionError.recordingFailed
        }
        
        // 停止录制计时器
        stopRecordingTimer()
        
        // 返回异步任务结果
        return try await Task<String, Error> { [weak self] in
            guard let self = self else { throw VoiceRecognitionError.recordingFailed }
            
            // 获取音频数据并进行识别
            return try await withCheckedThrowingContinuation { continuation in
                self.audioRecorder.stopRecording { audioData in
                    self.handleAudioData(audioData, continuation: continuation)
                }
            }
        }.value
    }
    
    /// 取消当前操作
    public func cancel() {
        logger.info("Cancelling voice recognition")
        
        stopRecordingTimer()
        if audioRecorder.isRecording {
            audioRecorder.stopRecording(completion: nil)
        }
        state = .idle
    }
    
    /// 重置状态为 idle
    /// 可以在需要手动重置状态时调用此方法
    public func resetState() {
        logger.info("Manually resetting state to idle")
        state = .idle
    }
    
    // MARK: - Private methods
    
    /// 处理音频数据
    private func handleAudioData(_ audioData: Data?, continuation: CheckedContinuation<String, Error>) {
        // 验证音频数据
        guard let audioData = audioData else {
            state = .failure(VoiceRecognitionError.recordingFailed)
            logger.error("Failed to retrieve audio data")
            continuation.resume(throwing: VoiceRecognitionError.recordingFailed)
            scheduleStateReset()
            return
        }
        
        // 更新状态
        state = .processing
        logger.debug("Processing audio data: \(audioData.count) bytes")
        
        // 创建识别任务
        Task {
            do {
                // 编码音频数据
                let base64Audio = audioData.base64EncodedString()
                logger.debug("Audio data encoded to Base64 format")
                
                // 创建识别请求
                let request = createRecognitionRequest(base64Audio: base64Audio)
                
                // 发送请求并获取结果
                logger.info("Sending recognition request to API")
                let result = try await sendRecognitionRequest(request)
                
                // 处理成功结果
                state = .success(result.text)
                logger.info("Voice recognition completed successfully: \(result.text.count) characters")
                continuation.resume(returning: result.text)
                scheduleStateReset()
                
            } catch {
                // 处理错误
                logger.error("Voice recognition failed: \(error.localizedDescription)")
                state = .failure(error)
                continuation.resume(throwing: error)
                scheduleStateReset()
            }
        }
    }
    
    /// 创建识别请求
    private func createRecognitionRequest(base64Audio: String) -> VoiceRecognitionRequest {
        VoiceRecognitionRequest(
            audioData: base64Audio,
            audioFormat: "m4a",
            engineType: "16k_zh",
            wordInfo: 0,
            filterDirty: 1,
            filterModal: 1,
            filterPunc: 0,
            convertNumMode: 1
        )
    }
    
    /// 设置延迟重置状态
    private func scheduleStateReset(_ delay: UInt64 = 500_000_000) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay) // 等待0.5秒
            state = .idle
            logger.debug("State reset to idle, ready for new recording")
        }
    }
    
    /// 启动录制时间计时器
    private func startRecordingTimer() {
        stopRecordingTimer()
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, 
                  let startTime = self.recordingStartTime, 
                  case .recording = self.state else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            // 更新录制状态
            self.state = .recording(elapsed)
            
            // 检查是否达到最大录制时长
            if elapsed >= self.recordingDuration {
                self.logger.info("Maximum recording duration reached (\(self.recordingDuration)s), automatically stopping")
                self.stopRecordingTimer()
                
                // 异步执行识别
                Task {
                    do {
                        _ = try await self.stopRecordingAndRecognize()
                    } catch {
                        self.logger.error("Auto-stop recognition failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// 停止录制时间计时器
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    /// 发送语音识别请求
    /// - Parameter request: 语音识别请求
    /// - Returns: 识别响应
    /// - Throws: VoiceRecognitionError
    private func sendRecognitionRequest(_ request: VoiceRecognitionRequest) async throws -> VoiceRecognitionResponse {
        logger.debug("Preparing to send recognition request")
        
        let endpoint = VoiceEndpoint.recognizeVoice
        
        let result: Result<VoiceRecognitionResponse, APIError> = await APIClient.shared.request(
            endpoint,
            parameters: request.asDictionary()
        )
        
        switch result {
        case .success(let response):
            logger.debug("Recognition request successful, audio duration: \(response.audioDuration)ms")
            return response
        case .failure(let error):
            logger.error("Recognition request failed: \(error.localizedDescription)")
            throw VoiceRecognitionError.apiRequestFailed(error)
        }
    }
}

// MARK: - 工具扩展

extension Encodable {
    /// 将编码对象转换为字典
    func asDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
} 

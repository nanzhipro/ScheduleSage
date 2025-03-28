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
    /// 音频录制器
    private var audioRecorder: AudioRecorderProtocol
    
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
        audioRecorder: AudioRecorderProtocol = AudioRecorder(),
        logger: LoggerService = .makeCompatible(category: "VoiceRecognitionService")
    ) {
        self.audioRecorder = audioRecorder
        self.logger = logger
        
        // 设置回调
        self.audioRecorder.onLevelChanged = { [weak self] level in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.onLevelChanged?(level)
            }
        }
        
        self.audioRecorder.onErrorOccurred = { [weak self] error in
            guard let self = self else { return }
            self.logger.error("录音错误: \(error.localizedDescription)")
            self.state = .failure(error)
            self.stopRecordingTimer()
        }
        
        // 配置录音器
        self.audioRecorder.configure(with: AudioRecorderSettings(
            sampleRate: 16000.0,
            channels: 1,
            enableLevelMonitoring: true,
            useHardwareFormat: true // 使用硬件格式，避免格式不匹配导致的崩溃
        ))
    }
    
    // MARK: - Public methods
    
    /// 请求麦克风访问权限
    /// - Parameter completion: 权限请求完成后的回调，参数表示是否获得权限
    public func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        logger.info("请求麦克风访问权限")
        audioRecorder.requestMicrophoneAccess { granted in
            self.logger.info("麦克风权限请求结果: \(granted ? "已授权" : "已拒绝")")
            completion(granted)
        }
    }
    
    /// 开始语音录制和识别
    /// - Returns: 是否成功开始录制
    @discardableResult
    public func startRecording() -> Bool {
        logger.info("开始语音录制")
        
        // 状态检查
        guard case .idle = state else {
            logger.warning("无法开始录制：当前状态\(state)不允许开始新的录制")
            return false
        }
        
        state = .preparing
        
        // 开始录制
        if audioRecorder.startRecording() {
            recordingStartTime = Date()
            startRecordingTimer()
            state = .recording(0)
            logger.info("语音录制已开始")
            return true
        } else {
            logger.error("语音录制失败")
            state = .failure(VoiceRecognitionError.recordingFailed)
            return false
        }
    }
    
    /// 停止录制并进行识别
    /// - Returns: 识别结果文本
    /// - Throws: VoiceRecognitionError
    public func stopRecordingAndRecognize() async throws -> String {
        logger.info("停止录制并开始识别")
        
        // 状态检查
        guard case .recording = state else {
            logger.warning("无法停止录制：当前状态\(state)不是录制状态")
            throw VoiceRecognitionError.recordingFailed
        }
        
        // 停止录制计时器
        stopRecordingTimer()
        
        // 停止录制并获取音频数据
        guard let buffer = audioRecorder.stopRecording() else {
            logger.error("获取录音数据失败")
            state = .failure(VoiceRecognitionError.recordingFailed)
            throw VoiceRecognitionError.recordingFailed
        }
        
        // 更新状态
        state = .processing
        
        do {
            // 将PCM数据转换为WAV格式
            let wavData = try convertPCMBufferToWAV(buffer)
            
            // 将音频数据编码为Base64
            let base64Audio = wavData.base64EncodedString()
            
            // 创建识别请求
            let request = VoiceRecognitionRequest(
                audioData: base64Audio,
                audioFormat: "wav",
                engineType: "16k_zh", // 使用16kHz中文引擎
                wordInfo: 0,          // 不需要词级别时间戳
                filterDirty: 1,       // 过滤脏词
                filterModal: 1,       // 部分过滤语气词
                filterPunc: 0,        // 不过滤标点
                convertNumMode: 1     // 智能转换数字
            )
            
            // 发送识别请求
            let result = try await sendRecognitionRequest(request)
            
            // 更新状态
            state = .success(result.text)
            logger.info("语音识别成功，结果：\(result.text)")
            return result.text
            
        } catch {
            logger.error("语音识别失败: \(error.localizedDescription)")
            state = .failure(error)
            throw error
        }
    }
    
    /// 取消当前操作
    public func cancel() {
        logger.info("取消语音识别")
        
        stopRecordingTimer()
        audioRecorder.reset()
        state = .idle
    }
    
    // MARK: - Private methods
    
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
                self.logger.info("已达到最大录制时长\(self.recordingDuration)秒，自动停止录制")
                self.stopRecordingTimer()
                
                // 异步执行识别，避免在Timer回调中执行异步操作
                Task {
                    do {
                        _ = try await self.stopRecordingAndRecognize()
                    } catch {
                        self.logger.error("自动停止录制后识别失败: \(error.localizedDescription)")
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
    
    /// 将PCM缓冲区转换为WAV格式数据
    /// - Parameter buffer: PCM音频缓冲区
    /// - Returns: WAV格式的Data
    /// - Throws: VoiceRecognitionError
    private func convertPCMBufferToWAV(_ buffer: AVAudioPCMBuffer) throws -> Data {
        logger.debug("开始转换PCM数据为WAV格式")
        
        // 创建临时文件
        let tempWavURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".wav")
        
        do {
            // 创建WAV文件写入器
            let format = buffer.format
            let bitDepth: Int = format.commonFormat == .pcmFormatInt16 ? 16 : 32
            let isFloat: Bool = format.commonFormat == .pcmFormatFloat32
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVLinearPCMBitDepthKey: bitDepth,
                AVLinearPCMIsFloatKey: isFloat,
                AVLinearPCMIsNonInterleaved: !format.isInterleaved
            ]
            
            let audioFile = try AVAudioFile(forWriting: tempWavURL, settings: settings)
            try audioFile.write(from: buffer)
            
            // 从文件中读取数据
            let wavData = try Data(contentsOf: tempWavURL)
            
            // 删除临时文件
            try FileManager.default.removeItem(at: tempWavURL)
            
            logger.debug("PCM转WAV成功，大小：\(wavData.count) 字节")
            return wavData
        } catch {
            logger.error("PCM转WAV失败: \(error.localizedDescription)")
            // 清理临时文件
            try? FileManager.default.removeItem(at: tempWavURL)
            throw VoiceRecognitionError.audioProcessingFailed
        }
    }
    
    /// 发送语音识别请求
    /// - Parameter request: 语音识别请求
    /// - Returns: 识别响应
    /// - Throws: VoiceRecognitionError
    private func sendRecognitionRequest(_ request: VoiceRecognitionRequest) async throws -> VoiceRecognitionResponse {
        logger.info("发送语音识别请求")
        
        let endpoint = VoiceEndpoint.recognizeVoice
        
        let result: Result<VoiceRecognitionResponse, APIError> = await APIClient.shared.request(
            endpoint,
            parameters: request.asDictionary()
        )
        
        switch result {
        case .success(let response):
            logger.info("识别请求成功，音频时长：\(response.audioDuration)毫秒")
            return response
        case .failure(let error):
            logger.error("识别请求失败: \(error.localizedDescription)")
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

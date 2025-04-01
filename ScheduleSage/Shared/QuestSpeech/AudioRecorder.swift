//
//  AudioRecorder.swift
//  AudioR
//
//  Created by CursorAI on 2024-04-02.
//

import Foundation
import AVFoundation
import Combine

/// 音频录制服务协议
/// Protocol defining the audio recording service interface
public protocol AudioRecordingService {
    /// 当前录制状态
    var isRecording: Bool { get }
    
    /// 当前播放状态
    var isPlaying: Bool { get }
    
    /// 是否有可用的录音
    var hasRecording: Bool { get }
    
    /// 录音的持续时间（秒）
    var duration: TimeInterval { get }
    
    /// 麦克风权限状态
    var hasMicrophonePermission: Bool { get }
    
    /// 音频数据
    var audioData: Data? { get }
    
    /// 开始录音
    /// - Returns: 是否成功启动录音
    func startRecording() -> Bool
    
    /// 停止录音
    /// - Parameter completion: 录音完成回调，参数为录制的音频数据
    func stopRecording(completion: ((Data?) -> Void)?)
    
    /// 播放录音
    /// - Returns: 是否成功开始播放
    func play() -> Bool
    
    /// 停止播放
    func stopPlaying()
}

/// 音频录制服务实现
/// Implementation of the audio recording service
public class AudioRecorder: NSObject, AudioRecordingService, ObservableObject {
    // MARK: - Published Properties
    
    @Published public private(set) var isRecording = false
    @Published public private(set) var isPlaying = false
    @Published public private(set) var hasRecording = false
    @Published public private(set) var duration: TimeInterval = 0
    @Published public private(set) var hasMicrophonePermission = false
    @Published public private(set) var currentRecordingTime: TimeInterval = 0
    @Published public private(set) var estimatedFileSize: Int = 0
    
    // MARK: - Private Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var tempURL: URL? // 临时文件URL，仅用于录制过程
    private var _audioData: Data?
    private let logger: LoggerService
    
    // 临时文件的唯一标识符
    private let tempFileName = "temp_recording_\(UUID().uuidString).m4a"
    
    private var recordingTimer: Timer?
    private let maxRecordingDuration: TimeInterval = 300 // 5分钟 = 300秒
    
    // MARK: - Public Properties
    
    public var audioData: Data? {
        return _audioData
    }
    
    // MARK: - Initialization
    
    public override init() {
        self.logger = LoggerService.makeCompatible(category: "AudioRecorder")
        super.init()
        checkMicrophonePermission()
    }
    
    // MARK: - AudioRecordingService Implementation
    
    public func startRecording() -> Bool {
        // 停止任何播放中的音频
        stopPlaying()
        
        // 重置录制计时器
        currentRecordingTime = 0
        estimatedFileSize = 0
        
        // 检查麦克风权限
        if !requestMicrophonePermissionIfNeeded() {
            logger.warning("Cannot start recording: microphone permission not granted")
            return false
        }
        
        do {
            // AVAudioRecorder 需要一个文件URL来写入数据，我们使用临时文件
            let tempDirectory = FileManager.default.temporaryDirectory
            tempURL = tempDirectory.appendingPathComponent(tempFileName)
            
            // 优化音频设置以减小文件大小
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 22050, // 降低采样率（从44100降至22050）
                AVNumberOfChannelsKey: 1, // 使用单声道而非立体声
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue, // 降低质量
                AVEncoderBitRateKey: 16000 // 设置低比特率 (16kbps)
            ]
            
            audioRecorder = try AVAudioRecorder(url: tempURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            
            // 设置录制时长限制和计时器
            startRecordingTimer()
            
            logger.info("Recording started successfully with optimized settings")
            return true
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            return false
        }
    }
    
    public func stopRecording(completion: ((Data?) -> Void)? = nil) {
        // 停止计时器
        stopRecordingTimer()
        
        guard isRecording, let recorder = audioRecorder else {
            logger.debug("No active recording to stop")
            completion?(nil)
            return
        }
        
        recorder.stop()
        isRecording = false
        logger.info("Recording stopped")
        
        // 从临时文件读取数据
        if let url = tempURL, FileManager.default.fileExists(atPath: url.path) {
            do {
                // 读取音频数据
                _audioData = try Data(contentsOf: url)
                hasRecording = true
                
                // 先更新音频时长，确保文件不会被提前删除
                updateAudioDuration(from: url) { [weak self] in
                    // 在时长更新完成后删除临时文件
                    do {
                       try FileManager.default.removeItem(at: url)
                        self?.logger.debug("Temporary audio file removed: \(url.lastPathComponent)")
                    } catch {
                        self?.logger.error("Failed to remove temporary file: \(error.localizedDescription)")
                    }
                }
                
                // 调用完成回调
                completion?(_audioData)
            } catch {
                logger.error("Failed to read recording data: \(error.localizedDescription)")
                completion?(nil)
            }
        } else {
            logger.warning("Temporary audio file not found")
            completion?(nil)
        }
    }
    
    public func play() -> Bool {
        guard hasRecording, let data = _audioData else {
            logger.warning("Cannot play: no recording available")
            return false
        }
        
        stopRecording()
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            logger.info("Started playing audio")
            return true
        } catch {
            logger.error("Failed to play recording: \(error.localizedDescription)")
            return false
        }
    }
    
    public func stopPlaying() {
        guard isPlaying else {
            return
        }
        
        audioPlayer?.stop()
        isPlaying = false
        logger.debug("Playback stopped")
    }
    
    // MARK: - Private Methods
    
    /// 请求麦克风权限（如果需要）
    /// - Returns: 是否已授权
    private func requestMicrophonePermissionIfNeeded() -> Bool {
        // 如果已授权，直接返回
        if hasMicrophonePermission { return true }
        
        logger.info("Requesting microphone permission")
        
        // 触发权限请求对话框
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasMicrophonePermission = granted
                if let self = self {
                    self.logger.info("Microphone permission \(granted ? "granted" : "denied")")
                }
            }
        }
        
        // 返回当前的权限状态
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    /// 检查麦克风权限状态
    private func checkMicrophonePermission() {
        hasMicrophonePermission = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        logger.debug("Current microphone permission: \(hasMicrophonePermission ? "granted" : "not granted")")
    }
    
    /// 更新音频文件的持续时间
    /// - Parameters:
    ///   - url: 音频文件URL
    ///   - completion: 时长更新完成的回调
    private func updateAudioDuration(from url: URL, completion: (() -> Void)? = nil) {
        let asset = AVURLAsset(url: url)
        
        if #available(macOS 13.0, *) {
            Task {
                do {
                    let durationTime = try await asset.load(.duration)
                    let seconds = CMTimeGetSeconds(durationTime)
                    
                    await MainActor.run {
                        self.duration = seconds
                        self.logger.debug("Audio duration updated: \(String(format: "%.2f", seconds))s")
                        completion?()
                    }
                } catch {
                    logger.error("Failed to get audio duration: \(error.localizedDescription)")
                    completion?()
                }
            }
        } else {
            // 对于较旧的 macOS 版本，使用同步方法
            let durationTime = asset.duration
            let seconds = CMTimeGetSeconds(durationTime)
            
            self.duration = seconds
            self.logger.debug("Audio duration updated: \(String(format: "%.2f", seconds))s")
            completion?()
        }
    }
    
    // 添加新方法来管理录制计时器
    private func startRecordingTimer() {
        // 停止现有计时器
        stopRecordingTimer()
        
        // 创建新计时器，每秒更新一次
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            
            self.currentRecordingTime += 1
            
            // 估算文件大小 (根据当前测试数据换算)
            // 使用优化后的设置，估计大约是原始大小的1/4
            let estimatedBytesPerSecond = 422 * 1024 / 28 / 4 // 约 3.75 KB/s
            self.estimatedFileSize = Int(self.currentRecordingTime * Double(estimatedBytesPerSecond))
            
            // 检查是否达到最大录制时长
            if self.currentRecordingTime >= self.maxRecordingDuration {
                self.logger.info("Maximum recording duration reached (5 minutes)")
                self.stopRecording(completion: nil)
            }
            
            // 检查文件大小是否接近 3MB 限制 (留一点余量)
            let maxFileSize = 2.9 * 1024 * 1024 // 2.9MB in bytes
            if Double(self.estimatedFileSize) >= maxFileSize {
                self.logger.info("Maximum file size approached (3MB)")
                self.stopRecording(completion: nil)
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            isRecording = false
            logger.warning("Recording finished unsuccessfully")
        } else {
            logger.debug("Recording finished successfully")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorder: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        logger.debug("Playback finished \(flag ? "successfully" : "unsuccessfully")")
    }
} 

//
//  AudioRecorderProtocol.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-17.
//

import Foundation
import AVFoundation

/// 定义音频录制模块的行为
public protocol AudioRecorderProtocol {
    /// 当前录制状态
    var isRecording: Bool { get }
    
    /// 录制过程中发生错误时的回调
    var onErrorOccurred: ((Error) -> Void)? { get set }
    
    /// 音频级别变化时的回调，值范围0.0-1.0
    var onLevelChanged: ((Float) -> Void)? { get set }
    
    /// 请求麦克风访问权限
    /// - Parameter completion: 权限请求完成后的回调，参数表示是否获得权限
    func requestMicrophoneAccess(completion: @escaping (Bool) -> Void)
    
    /// 配置音频录制设置
    /// - Parameter settings: 音频录制配置
    func configure(with settings: AudioRecorderSettings)
    
    /// 开始录制音频
    /// - Returns: 如果成功开始录制返回true，否则返回false
    @discardableResult
    func startRecording() -> Bool
    
    /// 停止录制音频
    /// - Returns: 返回录制的音频数据缓冲区，如果录制失败则返回nil
    func stopRecording() -> AVAudioPCMBuffer?
    
    /// 重置录制器状态
    func reset()
}

/// 音频录制设置
public struct AudioRecorderSettings {
    /// 采样率，默认为44100 Hz
    public let sampleRate: Double
    
    /// 声道数，默认为1（单声道）
    public let channels: Int
    
    /// 是否需要音频电平监测
    public let enableLevelMonitoring: Bool
    
    /// 是否使用硬件格式（避免格式转换导致的崩溃）
    public let useHardwareFormat: Bool
    
    /// 初始化录制设置
    /// - Parameters:
    ///   - sampleRate: 采样率，默认为44100 Hz
    ///   - channels: 声道数，默认为1（单声道）
    ///   - enableLevelMonitoring: 是否需要音频电平监测，默认为false
    ///   - useHardwareFormat: 是否使用硬件格式，默认为true（推荐）
    public init(
        sampleRate: Double = 44100.0,
        channels: Int = 1,
        enableLevelMonitoring: Bool = false,
        useHardwareFormat: Bool = true
    ) {
        self.sampleRate = sampleRate
        self.channels = channels
        self.enableLevelMonitoring = enableLevelMonitoring
        self.useHardwareFormat = useHardwareFormat
    }
}

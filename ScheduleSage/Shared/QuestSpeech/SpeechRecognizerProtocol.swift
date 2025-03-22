//
//  SpeechRecognizerProtocol.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-17.
//

import Foundation
import Speech
import AVFoundation

/// 定义语音识别模块的行为
public protocol SpeechRecognizerProtocol {
    /// 当前识别状态
    var isRecognizing: Bool { get }
    
    /// 语音识别支持的语言列表
    var supportedLocales: [Locale] { get }
    
    /// 当前选择的语言设置
    var currentLocale: Locale { get }
    
    /// 是否需要设备上进行识别(而非服务器端)
    var requiresOnDeviceRecognition: Bool { get set }
    
    /// 当识别结果更新时的回调
    var onTranscriptionUpdated: ((String) -> Void)? { get set }
    
    /// 识别完成时的回调，包含最终结果和可能的错误
    var onRecognitionFinished: ((String?, Error?) -> Void)? { get set }
    
    /// 检查语音识别服务是否可用
    /// - Returns: 如果语音识别服务可用返回true，否则返回false
    func isServiceAvailable() -> Bool
    
    /// 请求语音识别权限
    /// - Parameter completion: 权限请求完成后的回调，参数表示是否获得权限
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    
    /// 设置语音识别使用的语言
    /// - Parameter locale: 要使用的语言区域
    /// - Returns: 设置是否成功
    @discardableResult
    func setLocale(_ locale: Locale) -> Bool
    
    /// 开始从提供的音频缓冲区识别语音
    /// - Parameter buffer: 包含要识别语音的音频缓冲区
    /// - Returns: 如果成功开始识别返回true，否则返回false
    @discardableResult
    func startRecognition(from buffer: AVAudioPCMBuffer) -> Bool
    
    /// 开始实时语音识别
    /// - Returns: 如果成功开始识别返回true，否则返回false
    @discardableResult
    func startLiveRecognition() -> Bool
    
    /// 停止当前的语音识别
    func stopRecognition()
}

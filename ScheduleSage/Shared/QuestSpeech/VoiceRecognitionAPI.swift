//
//  VoiceRecognitionAPI.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-03.
//

import Foundation
import AVFoundation

/// 语音识别服务协议
/// 定义了语音识别模块的核心行为
public protocol VoiceRecognitionServiceProtocol {
    /// 当前识别状态
    var state: VoiceRecognitionState { get }
    
    /// 状态变化回调
    var onStateChanged: ((VoiceRecognitionState) -> Void)? { get set }
    
    /// 音频电平变化回调，值范围0.0-1.0
    var onLevelChanged: ((Float) -> Void)? { get set }
    
    /// 请求麦克风访问权限
    /// - Parameter completion: 权限请求完成后的回调，参数表示是否获得权限
    func requestMicrophoneAccess(completion: @escaping (Bool) -> Void)
    
    /// 开始语音录制
    /// - Returns: 是否成功开始录制
    @discardableResult
    func startRecording() -> Bool
    
    /// 停止录制并进行识别
    /// - Returns: 识别结果文本
    /// - Throws: VoiceRecognitionError
    func stopRecordingAndRecognize() async throws -> String
    
    /// 取消当前操作
    func cancel()
}

/// 语音识别状态
public enum VoiceRecognitionState: Equatable {
    /// 闲置状态
    case idle
    /// 准备中
    case preparing
    /// 录制中，参数为已录制时长（秒）
    case recording(TimeInterval)
    /// 处理中
    case processing
    /// 识别成功，参数为识别结果
    case success(String)
    /// 识别失败，参数为错误信息
    case failure(Error)
    
    public static func == (lhs: VoiceRecognitionState, rhs: VoiceRecognitionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.preparing, .preparing),
             (.processing, .processing):
            return true
            
        case (.recording(let lhsDuration), .recording(let rhsDuration)):
            return lhsDuration == rhsDuration
            
        case (.success(let lhsText), .success(let rhsText)):
            return lhsText == rhsText
            
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        default:
            return false
        }
    }
}

/// 语音识别服务错误类型
public enum VoiceRecognitionError: Error {
    /// 音频录制失败
    case recordingFailed
    /// 音频数据处理失败
    case audioProcessingFailed
    /// API请求失败
    case apiRequestFailed(Error)
    /// 服务器响应无效
    case invalidResponse(Int)
    /// 响应数据解析失败
    case decodingFailed(Error)
    /// 麦克风权限被拒绝
    case microphonePermissionDenied
}

// 扩展错误类型，添加本地化描述
extension VoiceRecognitionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .recordingFailed:
            return NSLocalizedString("voice_recognition_recording_failed", comment: "录音失败")
        case .audioProcessingFailed:
            return NSLocalizedString("voice_recognition_processing_failed", comment: "音频处理失败")
        case .apiRequestFailed(let error):
            return String(format: NSLocalizedString("voice_recognition_api_request_failed", comment: "API请求失败: %@"), error.localizedDescription)
        case .invalidResponse(let code):
            return String(format: NSLocalizedString("voice_recognition_invalid_response", comment: "服务器响应无效: 状态码 %d"), code)
        case .decodingFailed(let error):
            return String(format: NSLocalizedString("voice_recognition_decoding_failed", comment: "响应数据解析失败: %@"), error.localizedDescription)
        case .microphonePermissionDenied:
            return NSLocalizedString("voice_recognition_permission_denied", comment: "麦克风权限被拒绝，请在系统设置中允许访问麦克风")
        }
    }
} 
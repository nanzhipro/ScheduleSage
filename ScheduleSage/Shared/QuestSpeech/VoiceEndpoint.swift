//
//  VoiceEndpoint.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-03.
//

import Foundation
import Alamofire

/// 语音服务相关API端点
public enum VoiceEndpoint: Endpoint {
    /// 语音识别请求
    case recognizeVoice
    
    public var path: String {
        switch self {
        case .recognizeVoice:
            return "/api/v1/voice/recognize"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .recognizeVoice:
            return .post
        }
    }
    
    public var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    public var timeout: TimeInterval? {
        switch self {
        case .recognizeVoice:
            return 120 // 较长超时时间，因为语音识别可能需要较长处理时间
        }
    }
} 
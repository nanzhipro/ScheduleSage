//
//  VoiceModels.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-06-03.
//

import Foundation

/// 语音识别请求模型
public struct VoiceRecognitionRequest: Codable {
    /// 语音数据（Base64编码）
    public let audioData: String
    /// 音频格式，默认为wav
    public let audioFormat: String?
    /// 引擎类型，默认为16k_zh
    public let engineType: String?
    /// 是否显示词级别时间戳 (0: 不显示; 1: 显示，不包含标点; 2: 显示，包含标点)
    public let wordInfo: Int?
    /// 是否过滤脏词 (0: 不过滤; 1: 过滤; 2: 用*替代)
    public let filterDirty: Int?
    /// 是否过滤语气词 (0: 不过滤; 1: 部分过滤; 2: 严格过滤)
    public let filterModal: Int?
    /// 是否过滤标点符号 (0: 不过滤; 1: 过滤句末标点; 2: 过滤所有标点)
    public let filterPunc: Int?
    /// 是否进行阿拉伯数字智能转换 (0: 不转换; 1: 根据场景智能转换)
    public let convertNumMode: Int?
    
    /// 创建语音识别请求
    /// - Parameters:
    ///   - audioData: 语音数据（Base64编码）
    ///   - audioFormat: 音频格式，默认为"wav"
    ///   - engineType: 引擎类型，默认为"16k_zh"
    ///   - wordInfo: 词级别时间戳设置，默认为0
    ///   - filterDirty: 脏词过滤设置，默认为1
    ///   - filterModal: 语气词过滤设置，默认为1
    ///   - filterPunc: 标点符号过滤设置，默认为0
    ///   - convertNumMode: 数字转换模式，默认为1
    public init(
        audioData: String,
        audioFormat: String? = "wav",
        engineType: String? = "16k_zh",
        wordInfo: Int? = 0,
        filterDirty: Int? = 1,
        filterModal: Int? = 1,
        filterPunc: Int? = 0,
        convertNumMode: Int? = 1
    ) {
        self.audioData = audioData
        self.audioFormat = audioFormat
        self.engineType = engineType
        self.wordInfo = wordInfo
        self.filterDirty = filterDirty
        self.filterModal = filterModal
        self.filterPunc = filterPunc
        self.convertNumMode = convertNumMode
    }
}

/// 语音识别响应模型
public struct VoiceRecognitionResponse: Codable {
    /// 识别结果文本
    public let text: String
    /// 请求的音频时长（毫秒）
    public let audioDuration: Int
    /// 词时间戳列表（仅当请求中启用了wordInfo时有效）
    public let words: [WordInfo]?
    /// 请求ID
    public let requestId: String
}

/// 词时间戳信息
public struct WordInfo: Codable {
    /// 词文本
    public let text: String
    /// 开始时间（毫秒）
    public let startTime: Int
    /// 结束时间（毫秒）
    public let endTime: Int
} 
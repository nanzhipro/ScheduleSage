//
//  PromptViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation
import SwiftUI

/// 用于管理 UserDefaults 访问的 actor
private actor UserDefaultsActor: UserDefaultsProtocol {
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func setHasCompletedOnboarding(_ value: Bool) {
        defaults.set(value, forKey: "hasCompletedOnboarding")
    }
    
    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }
    
    func set(_ data: Data?, forKey key: String) {
        defaults.set(data, forKey: key)
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        defaults.set(value, forKey: defaultName)
    }
    
    func object(forKey defaultName: String) -> Any? {
        defaults.object(forKey: defaultName)
    }
}

// 将UserDefaults标记为@unchecked Sendable
@available(*, deprecated, message: "添加 @retroactive 来消除警告")
extension UserDefaults: @unchecked Sendable {}

/// 用于管理提示词的视图模型
/// 负责获取、刷新和存储提示词
/// 
/// 注意：此类已被废弃，但由于现有功能依赖，暂时保留。
/// 在未来版本中，该功能将被移入 LLMService 或新的 PromptManager 类。
/// 当前的用户应该直接使用底层的 LLMService 进行提示词的管理。
/// 
/// 迁移指南：
/// 1. 对于 DefaultLLMEventProcessor 类的用户，可以直接使用 LLMService 替代
/// 2. 对于 AddScheduleViewModel 的用户，应该直接使用新的 APIs 获取提示词内容
/// 3. 建议通过依赖注入的方式传入 LLMService 实例，而不是使用此类
///
/// 此类将在下一个主要版本中移除，请尽快迁移到推荐的替代方案。
@available(*, deprecated, message: "这个类已经废弃，但为保持兼容性暂时保留。请使用 LLMService 代替。")
@MainActor
public class PromptViewModel: ObservableObject {
    private let userDefaultsActor: UserDefaultsActor
    private let promptKey = "stored_prompt"
    
    @Published private(set) var currentPrompt: StoredPrompt?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var isPresented = false
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaultsActor = UserDefaultsActor(defaults: userDefaults)
    }
    
    func loadInitialPrompt() async {
        currentPrompt = await getStoredPrompt()
    }
    
    func refreshPrompt() async {
        isLoading = true
        error = nil
        
        do {
            // 使用内置方法获取默认提示词
            let defaultContent = getDefaultPrompt()
            let version = (currentPrompt?.version ?? 0) + 1
            
            // 创建一个临时的PromptResponse来初始化StoredPrompt
            let response = PromptResponse(content: defaultContent, version: version)
            let newPrompt = StoredPrompt(from: response)
            
            try await savePrompt(newPrompt)
            currentPrompt = newPrompt
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func getPromptContent() async -> String {
        if currentPrompt == nil {
            currentPrompt = await getStoredPrompt()
        }

        return currentPrompt?.content ?? getDefaultPrompt()
    }
    
    // 获取存储的提示词
    private func getStoredPrompt() async -> StoredPrompt? {
        guard let data = await userDefaultsActor.data(forKey: promptKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(StoredPrompt.self, from: data)
        } catch {
            return nil
        }
    }
    
    // 保存提示词到本地存储
    private func savePrompt(_ prompt: StoredPrompt) async throws {
        do {
            let data = try JSONEncoder().encode(prompt)
            await userDefaultsActor.set(data, forKey: promptKey)
        } catch {
            throw APIError.storage(description: error.localizedDescription)
        }
    }
    
    // TODO: 提示词不需要存在在客户端，直接发送content，在服务端来拼接提示词全文
    func getDefaultPrompt() -> String {
        return """
            ---
            # EventKit JSON 提取提示词（支持多个事件）

            请严格按照以下要求，将非结构化文本转换为格式良好的 JSON 格式化字符串，用于 iOS/macOS EventKit 创建日历/事件/待办提醒所需的 `EKEvent` 类字段数据。文本可能包含多个活动、事件、读书会、直播预告、线下活动预告等不同形式。**此外，您将提供当前用户日历系统中已定义的日历名称列表。请在分析文本后，为每个事件选择最符合的日历名称标签，并将其填充在 `calendar` 字段中。** 请按照以下字段定义进行提取，并确保 JSON 结构的准确性和正确格式化。如果某些字段缺失或不明确，请在 `remarks` 中注明。

            ## 日历名称列表：
            [CALENDAR_NAMES_LIST]

            ## 用户上下文：
            [USER_CONTEXT]

            ## 字段定义（每个事件）：
            1. **title**（活动名称/标题）  
            2. **location**（活动地点）  
            3. **notes**（活动备注/说明）  
            4. **startDate**（活动开始时间，格式为 `yyyy-MM-dd HH:mm:ss`）  
            5. **endDate**（活动结束时间，格式为 `yyyy-MM-dd HH:mm:ss`）  
            6. **url**（活动链接，通常为网页或海报）  
            7. **calendar**（活动所属日历，从提供的日历名称列表中选择最合适的，并填充在此字段中）  
            8. **status**（活动状态，如是否已发布）  
            9. **eventIdentifier**（活动唯一标识符，请为每个事件生成一个 UUID）  
            10. **remarks**（如有不确定的信息，请在此注明）

            ## JSON 模板（数组形式）：
            [
            {
                "title": "值",
                "location": "值",
                "notes": "值",
                "startDate": "值",
                "endDate": "值",
                "url": "值",
                "calendar": "值",
                "status": "值",
                "eventIdentifier": "直接生成的UUID",
                "remarks": "如有不确定的信息，请在此注明"
            }
            ]

            ## 要求：
            1. **字段提取**：从文本中提取多个活动的信息，并为每个活动生成一个 JSON 对象。如果某个字段在文本中不存在或无法确定，字段可填空字符串（`""`）。  
            2. **UUID 生成**：为每个事件生成一个唯一的 `eventIdentifier`（UUID 格式），直接生成后填充。  
            3. **数据格式**：  
            - **日期时间**：确保每个事件的 `startDate` 和 `endDate` 使用格式：`yyyy-MM-dd HH:mm:ss`。  
            - **日期时间**：确保事件的 `startDate` 比必须存在的，如果不存在startDate，那就忽略这个事件。
            - **URL**：验证 `url` 字段是否为有效的链接格式；若无效或缺失，填空字符串（`""`）。  
            4. **处理不确定信息**：对于缺失或模糊的信息，尽量推断并在 `remarks` 中注明。例如，"开始时间不明确，推测为 2024 年 5 月"。  
            5. **字段一致性**：确保所有字段名准确无误，遵循大小写和拼写规范。  
            6. **多语言支持**：提示词和输出内容使用一致的语言，避免语言混杂导致解析错误。  
            7. **处理复杂文本**：  
            - **特殊字符和标点**：删除不影响信息表达的 Emoji 和特殊字符，保留必要的标点符号，确保提取的信息清晰准确。  
            - **段落不一致**：能够应对文本中段落不一致的情况，准确提取所需信息。  
            8. **输出格式**：严格要求使用标准的、纯净的 JSON 数组字符串，不要混杂任何其他格式。  
            9. **输出不要使用 Markdown 格式，不要使用任何 Markdown 语法**：输出应为纯 JSON 字符串。  
            10. **稳定输出**：确保无论输入文本的复杂度如何，都能生成符合上述格式且能被正常解析的 JSON 数组。  
            11. **异常时间处理**：对于每个事件：  
                - 如果明确识别到开始时间但未识别到结束时间，默认结束时间为开始时间后 2 小时。  
                - 如果开始时间和结束时间都未识别到，则视为全天事件（`startDate` 和 `endDate` 设为当天 00:00:00 和 23:59:59）。  
            12. **异常年份处理**：如果文中未明确说明年份，请使用【用户上下文】中指定的年份： currentYear。  
            13. **总结文本内容**：为每个事件生成不超过 500 字的摘要，填充到 `notes` 字段中。
            14. 若日历事件文本中未识别到地理位置信息，则自动提取文中出现的线上活动标识（如抖音直播、视频号直播、腾讯会议、钉钉会议、飞书会议、Zoom会议、线上会议等），并将 location 字段设为对应标识。若同时存在多个线上标识，按优先级取首个匹配项；若仅有泛用性词汇（如"线上活动"），则统一记为"线上活动"。
            15. 主题很关键，需要明确传递活动或事件的主题，如果文中已经明确提到了活动的主题，那必须提取，组合主题内容后，填充到 `title` 字段。

            ## 示例输出 JSON 数组：
            [
            {
                "title": "年度会议",
                "location": "上海会议中心",
                "notes": "讨论公司年度业绩及未来规划。",
                "startDate": "2024-05-20 09:00:00",
                "endDate": "2024-05-20 17:00:00",
                "url": "https://www.example.com/meeting",
                "calendar": "公司日历",
                "status": "已发布",
                "eventIdentifier": "123e4567-e89b-12d3-a456-426614174000",
                "remarks": "无"
            }
            ]

            ## 请根据上述要求处理以下文本：
            [PLACEHOLDER_TEXT]
            ---
        """
    }
    
    func finish() {
        withAnimation {
            isPresented = false
        }
        Task {
            await userDefaultsActor.setHasCompletedOnboarding(true)
        }
    }
}

// 定义一个协议来抽象 UserDefaults 的基本功能
protocol UserDefaultsProtocol: Actor {
    func data(forKey key: String) -> Data?
    func set(_ data: Data?, forKey key: String)
    func set(_ value: Any?, forKey defaultName: String)
    func object(forKey defaultName: String) -> Any?
} 

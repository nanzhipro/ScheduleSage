//
//  PromptViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-02-22.
//

import Foundation

@MainActor
class PromptViewModel: ObservableObject {
    private let promptService = PromptService()
    
    @Published private(set) var currentPrompt: StoredPrompt?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    init() {
        // 初始化时不加载数据
    }
    
    func loadInitialPrompt() async {
        currentPrompt = await promptService.getStoredPrompt()
    }
    
    func refreshPrompt() async {
        isLoading = true
        error = nil
        
        do {
            currentPrompt = try await promptService.fetchLatestPrompt()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func getPromptContent() -> String {
        currentPrompt?.content ?? ""
    }
} 
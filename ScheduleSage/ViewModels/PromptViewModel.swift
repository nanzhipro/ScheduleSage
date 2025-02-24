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

@MainActor
public class PromptViewModel: ObservableObject {
    private let promptService: PromptService
    private let userDefaultsActor: UserDefaultsActor
    
    @Published private(set) var currentPrompt: StoredPrompt?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var isPresented = false
    
    init(userDefaults: UserDefaults = .standard) {
        let userDefaultsActor = UserDefaultsActor(defaults: userDefaults)
        self.userDefaultsActor = userDefaultsActor
        self.promptService = PromptService(storage: userDefaultsActor)
    }
    
    deinit {
        let service = promptService
        Task.detached {
            await service.stopPeriodicRefresh()
        }
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
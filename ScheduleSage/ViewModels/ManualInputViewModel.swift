//
//  ManualInputViewModel.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-20.
//

import Foundation
import OSLog

@MainActor
class ManualInputViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    @Published var parsedEvents: [CalendarEvent] = []
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ScheduleSage", category: "ManualInputViewModel")
    private let eventParsingService: EventParsingService
    private let promptViewModel: PromptViewModel
    private let calendarManager = CalendarManager()
    
    init() {
        self.promptViewModel = PromptViewModel()
        self.eventParsingService = EventParsingService(promptViewModel: promptViewModel)
        
        Task {
            logger.info("Initializing PromptViewModel...")
            await promptViewModel.loadInitialPrompt()
            await promptViewModel.refreshPrompt()
            logger.info("PromptViewModel initialization completed")
        }
    }
    
    func recognizeText(_ text: String) async {
        guard !text.isEmpty else { return }
        
        isProcessing = true
        LoadingManager.shared.show(.processing)
        
        do {
            // 1. 解析文本
            let event = try await eventParsingService.parseContent(text)
            parsedEvents = [event]
            
            // 2. 创建日历事件
            try await calendarManager.createEvent(from: event)
            
            // 3. 显示成功提示
            showToast = true
            toastType = .success
            toastMessage = NSLocalizedString("manual_input.calendar_created_success", comment: "")
            
        } catch CalendarManager.CalendarError.accessDenied {
            logger.error("Calendar access denied")
            showToast = true
            toastType = .error
            toastMessage = NSLocalizedString("calendar.error.access_denied", comment: "")
            
        } catch CalendarManager.CalendarError.createFailed {
            logger.error("Calendar creation failed")
            showToast = true
            toastType = .error
            toastMessage = NSLocalizedString("calendar.error.create_failed", comment: "")
            
        } catch {
            logger.error("Operation failed: \(error.localizedDescription)")
            showToast = true
            toastType = .error
            toastMessage = error.localizedDescription
        }
        
        isProcessing = false
        LoadingManager.shared.hide()
    }
} 

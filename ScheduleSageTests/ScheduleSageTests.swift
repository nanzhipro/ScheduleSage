//
//  ScheduleSageTests.swift
//  ScheduleSageTests
//
//  Created by CursorAI on 2024/11/26.
//

import Testing
import EventKit
@testable import ScheduleSage
import XCTest

struct ScheduleSageTests {
    let calendarManager = CalendarManager()
    
    // 辅助函数：等待权限授权
    private func waitForCalendarAccess() async throws -> Bool {
        return await withCheckedContinuation { continuation in
            calendarManager.requestAccess { granted, error in
                if let error = error {
                    print("Calendar access error: \(error.localizedDescription)")
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    @Test func testRequestAccess() async throws {
        let granted = try await waitForCalendarAccess()
        #expect(granted, "Calendar access should be granted")
    }
    
    @Test func testCreateEvent() async throws {
        // 首先确保有日历访问权限
        let granted = try await waitForCalendarAccess()
        #expect(granted, "Calendar access should be granted before creating event")
        
        // 如果没有权限，提前返回
        guard granted else {
            throw NSError(domain: "ScheduleSageTests",
                         code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Calendar access not granted"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let event = CalendarEvent(
                title: "Test Event",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                location: "Test Location",
                detailURL: URL(string: "https://example.com"),
                calendarName: "Test Calendar"
            )
            
            calendarManager.createEvent(from: event) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "ScheduleSageTests",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to create event without specific error"]
                    ))
                }
            }
        }
    }
    
    @Test func testGetAllCalendarNames() async throws {
        // 首先确保有日历访问权限
        let granted = try await waitForCalendarAccess()
        #expect(granted, "Calendar access should be granted before testing calendars")
        
        // 如果没有权限，提前返回
        guard granted else {
            throw NSError(domain: "ScheduleSageTests",
                         code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Calendar access not granted"])
        }
        
        // 创建测试日历
        try await withThrowingTaskGroup(of: Void.self) { group in
            // 创建第一个日历
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    let event1 = CalendarEvent(
                        title: "Test Event 1",
                        startDate: Date(),
                        endDate: Date().addingTimeInterval(3600),
                        location: "Test Location 1",
                        detailURL: nil,
                        calendarName: "Calendar 1"
                    )
                    
                    calendarManager.createEvent(from: event1) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }
            
            // 创建第二个日历
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    let event2 = CalendarEvent(
                        title: "Test Event 2",
                        startDate: Date(),
                        endDate: Date().addingTimeInterval(3600),
                        location: "Test Location 2",
                        detailURL: nil,
                        calendarName: "Calendar 2"
                    )
                    
                    calendarManager.createEvent(from: event2) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }
            
            // 等待所有任务完成
            try await group.waitForAll()
        }
        
        // 获取并验证日历名称
        let calendarNames = calendarManager.getAllCalendarNames()
        #expect(calendarNames.count >= 2, "Should have at least 2 calendars")
        #expect(calendarNames.contains("Calendar 1"), "Should contain Calendar 1")
        #expect(calendarNames.contains("Calendar 2"), "Should contain Calendar 2")
    }
}

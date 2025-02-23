//
//  User.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-19.
//

import Foundation

/// 用户模型
struct User: Codable, CustomStringConvertible, CustomDebugStringConvertible {
    let id: String
    let email: String?
    let name: String?
    let token: String
    
    // 用于基本描述
    var description: String {
        "User(id: \(id), email: \(email ?? "nil"), name: \(name ?? "nil"))"
    }
    
    // 用于调试信息，包含更多细节
    var debugDescription: String {
        """
        User {
            id: \(id)
            email: \(email ?? "nil")
            name: \(name ?? "nil")
            token: \(String(token.prefix(10)))... (truncated)
        }
        """
    }
    
    // 用于日志打印的简短版本
    var logDescription: String {
        "User[\(id)](\(name ?? "unnamed"))"
    }
    
    // 编码和解码时的键名
    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case token
    }
    
    // 自定义初始化方法，添加日志
    init(id: String, email: String?, name: String?, token: String) {
        self.id = id
        self.email = email
        self.name = name
        self.token = token
        
        #if DEBUG
        print("[User] Created: \(self.logDescription)")
        #endif
    }
    
    // 自定义解码方法，添加日志
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        token = try container.decode(String.self, forKey: .token)
        
        #if DEBUG
        print("[User] Decoded: \(self.logDescription)")
        #endif
    }
    
    // 自定义编码方法，添加日志
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(token, forKey: .token)
        
        #if DEBUG
        print("[User] Encoded: \(self.logDescription)")
        #endif
    }
}

// MARK: - Equatable
extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Identifiable
extension User: Identifiable {
    // id 已经存在，自动符合 Identifiable 协议
} 
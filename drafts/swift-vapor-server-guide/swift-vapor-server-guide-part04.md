    }
}

struct ErrorResponse: Content {
    let status: Int
    let reason: String
}

// 在 configure.swift 中使用中间件
app.middleware.use(GlobalErrorMiddleware())
```

这个全局错误处理中间件可以捕获所有未处理的错误，并将它们转换为适当的 HTTP 响应。它还会在遇到内部服务器错误时记录错误详情。

### 9.2 结构化日志记录

使用结构化日志可以使日志更易于搜索和分析。以下是一个使用结构化日志的示例：

```swift
import Vapor
import Logging

struct StructuredLogHandler: LogHandler {
    private let label: String
    
    init(label: String) {
        self.label = label
    }
    
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
    
    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .info
    
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        let prettyMetadata = metadata?.isEmpty ?? true
            ? self.metadata.isEmpty ? "" : " \(self.metadata)"
            : " \(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))"
        
        let logEntry = LogEntry(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            level: level.rawValue,
            message: message.description,
            metadata: prettyMetadata,
            source: source,
            file: file,
            function: function,
            line: line
        )
        
        print(logEntry.json)
    }
}

struct LogEntry: Codable {
    let timestamp: String
    let level: String
    let message: String
    let metadata: String
    let source: String
    let file: String
    let function: String
    let line: UInt
    
    var json: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try? encoder.encode(self)
        return String(data: data ?? Data(), encoding: .utf8) ?? "{}"
    }
}

// 在 configure.swift 中使用结构化日志处理器
LoggingSystem.bootstrap { label in
    StructuredLogHandler(label: label)
}
```

这个结构化日志处理器将日志条目格式化为 JSON，使其更易于被日志管理系统（如 ELK stack）处理。

### 9.3 上下文日志记录

在整个请求生命周期中保持一致的日志上下文可以帮助追踪请求：

```swift
import Vapor

struct RequestIdMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let requestId = UUID().uuidString
        request.headers.add(name: "X-Request-ID", value: requestId)
        request.logger[metadataKey: "request_id"] = .string(requestId)
        
        return next.respond(to: request).map { response in
            response.headers.add(name: "X-Request-ID", value: requestId)
            return response
        }
    }
}

// 在 configure.swift 中使用中间件
app.middleware.use(RequestIdMiddleware())

// 在路由处理程序中使用
app.get("example") { req -> String in
    req.logger.info("Processing request", metadata: ["path": .string(req.url.path)])
    return "Hello, World!"
}
```

这个中间件为每个请求生成一个唯一的 ID，并将其添加到请求头和日志元数据中。这使得可以轻松地跟踪整个请求生命周期中的日志条目。

### 9.4 性能日志记录

记录关键操作的# Swift Vapor 服务端实现详细指南 (续3)

## 8. 安全最佳实践 (续)

### 8.7 数据加密 (续)

对敏感数据进行加密存储是保护用户隐私的重要措施。以下是一个使用 AES-GCM 加密方法的示例：

```swift
import Vapor
import Crypto

struct EncryptedField<T: Codable>: Codable {
    let encryptedData: String
    
    init(_ value: T, using symmetricKey: SymmetricKey) throws {
        let data = try JSONEncoder().encode(value)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        self.encryptedData = sealedBox.combined!.base64EncodedString()
    }
    
    func decrypt(using symmetricKey: SymmetricKey) throws -> T {
        guard let data = Data(base64Encoded: encryptedData) else {
            throw Abort(.internalServerError, reason: "Failed to decode base64 string")
        }
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        return try JSONDecoder().decode(T.self, from: decryptedData)
    }
}

// 使用示例
struct User: Codable {
    let id: UUID
    let username: String
    let encryptedEmail: EncryptedField<String>
    
    init(id: UUID, username: String, email: String, encryptionKey: SymmetricKey) throws {
        self.id = id
        self.username = username
        self.encryptedEmail = try EncryptedField(email, using: encryptionKey)
    }
}

// 在应用中使用
let encryptionKey = SymmetricKey(size: .bits256)

app.post("users") { req -> EventLoopFuture<User> in
    let createUser = try req.content.decode(CreateUser.self)
    let user = try User(
        id: UUID(),
        username: createUser.username,
        email: createUser.email,
        encryptionKey: encryptionKey
    )
    return user.save(on: req.db).map { user }
}
```

这个示例展示了如何使用 AES-GCM 加密方法来加密用户的电子邮件地址。加密密钥应该安全地存储，并且不应该硬编码在代码中。考虑使用密钥管理系统或环境变量来管理加密密钥。

### 8.8 安全日志记录

安全日志记录对于监控应用程序的安全状态和调查潜在的安全事件至关重要。以下是一个实现安全日志记录的示例：

```swift
import Vapor
import Logging

struct SecurityLogger {
    let logger: Logger
    
    init(label: String) {
        self.logger = Logger(label: label)
    }
    
    func logSecurityEvent(_ event: SecurityEvent, request: Request) {
        let logMessage = """
        Security Event: \(event.description)
        IP: \(request.remoteAddress?.hostname ?? "unknown")
        User-Agent: \(request.headers.first(name: .userAgent) ?? "unknown")
        Path: \(request.url.path)
        Method: \(request.method.string)
        """
        
        logger.warning("\(logMessage)")
    }
}

enum SecurityEvent: CustomStringConvertible {
    case failedLogin(username: String)
    case successfulLogin(username: String)
    case unauthorizedAccess(resource: String)
    case suspiciousActivity(details: String)
    
    var description: String {
        switch self {
        case .failedLogin(let username):
            return "Failed login attempt for user: \(username)"
        case .successfulLogin(let username):
            return "Successful login for user: \(username)"
        case .unauthorizedAccess(let resource):
            return "Unauthorized access attempt to resource: \(resource)"
        case .suspiciousActivity(let details):
            return "Suspicious activity detected: \(details)"
        }
    }
}

// 在应用中使用
let securityLogger = SecurityLogger(label: "security.vapor.app")

app.post("login") { req -> EventLoopFuture<HTTPStatus> in
    let login = try req.content.decode(Login.self)
    return User.query(on: req.db)
        .filter(\.$username == login.username)
        .first()
        .flatMap { user in
            guard let user = user,
                  try Bcrypt.verify(login.password, created: user.passwordHash) else {
                securityLogger.logSecurityEvent(.failedLogin(username: login.username), request: req)
                return req.eventLoop.future(HTTPStatus.unauthorized)
            }
            securityLogger.logSecurityEvent(.successfulLogin(username: login.username), request: req)
            return req.eventLoop.future(HTTPStatus.ok)
        }
}
```

这个示例创建了一个专门的安全日志记录器，用于记录重要的安全事件。它包括有关请求的上下文信息，这在调查安全事件时非常有用。

### 8.9 安全配置检查

定期进行安全配置检查可以确保您的应用程序保持安全状态。以下是一个简单的安全配置检查示例：

```swift
import Vapor

struct SecurityConfigChecker {
    let app: Application
    
    func performChecks() -> [String] {
        var warnings: [String] = []
        
        // 检查是否启用了 HTTPS
        if app.http.server.configuration.tlsConfiguration == nil {
            warnings.append("HTTPS is not enabled")
        }
        
        // 检查会话配置
        if app.sessions.configuration.cookieFactory.secure == false {
            warnings.append("Session cookies are not set to secure")
        }
        
        // 检查 CORS 配置
        if let corsMiddleware = app.middleware.storage.compactMap({ $0 as? CORSMiddleware }).first {
            if corsMiddleware.configuration.allowedOrigin == .all {
                warnings.append("CORS is configured to allow all origins")
            }
        } else {
            warnings.append("CORS middleware is not configured")
        }
        
        // 检查路由是否使用身份验证
        let unauthenticatedRoutes = app.routes.all.filter { route in
            !route.middlewares.contains(where: { $0 is AuthenticationMiddleware })
        }
        if !unauthenticatedRoutes.isEmpty {
            warnings.append("Some routes are not protected by authentication: \(unauthenticatedRoutes.map { $0.description }.joined(separator: ", "))")
        }
        
        return warnings
    }
}

// 在应用启动时使用
let securityChecker = SecurityConfigChecker(app: app)
let warnings = securityChecker.performChecks()

if !warnings.isEmpty {
    app.logger.warning("Security configuration warnings:")
    warnings.forEach { app.logger.warning($0) }
}
```

这个安全配置检查器会检查几个常见的安全配置问题，并在应用程序启动时报告任何警告。您可以根据您的具体需求扩展这个检查器。

### 8.10 定期安全审计

定期进行安全审计是维护应用程序安全性的重要实践。以下是一些建议的安全审计步骤：

1. 代码审查：定期审查代码库，寻找潜在的安全漏洞。
2. 依赖检查：使用工具如 SwiftFormat 检查依赖项的已知漏洞。
3. 渗透测试：进行或委托进行定期渗透测试，以识别潜在的漏洞。
4. 日志审查：定期审查安全日志，寻找可疑活动。
5. 配置审查：检查所有环境（开发、测试、生产）的配置，确保它们符合安全最佳实践。
6. 访问控制审查：审查用户角色和权限，确保遵守最小权限原则。
7. 加密审查：确保所有敏感数据都使用最新的加密标准进行保护。
8. 安全策略审查：定期审查和更新安全策略和程序。

通过实施这些安全最佳实践，您可以显著提高 Vapor 应用程序的安全性。记住，安全是一个持续的过程，需要持续的关注和改进。

## 9. 错误处理和日志

有效的错误处理和日志记录对于维护健康的应用程序至关重要。以下是一些在 Vapor 中实现高级错误处理和日志记录的策略：

### 9.1 全局错误处理中间件

创建一个全局错误处理中间件可以确保所有未捕获的错误都得到适当的处理：

```swift
import Vapor

struct GlobalErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).flatMapErrorThrowing { error in
            let status: HTTPStatus
            let reason: String
            
            switch error {
            case let abort as AbortError:
                status = abort.status
                reason = abort.reason
            case let validation as ValidationsError:
                status = .badRequest
                reason = validation.description
            default:
                status = .internalServerError
                reason = "An internal error occurred"
                request.logger.report(error: error)
            }
            
            let errorResponse = ErrorResponse(status: status.code, reason: reason)
            return try Response(status: status, version: request.version, headers: [:], body: Response.Body(data: JSONEncoder().encode(errorResponse)))
        }
    }

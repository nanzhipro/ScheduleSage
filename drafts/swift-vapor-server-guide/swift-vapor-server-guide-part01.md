# Swift Vapor 服务端实现详细指南

## 1. 项目结构

Swift Vapor 项目的标准结构如下：

```
.
├── Dockerfile
├── Package.resolved
├── Package.swift
├── Public
├── Sources
│   └── App
│       ├── Controllers
│       │   └── TodoController.swift
│       ├── DTOs
│       │   └── TodoDTO.swift
│       ├── Migrations
│       │   └── CreateTodo.swift
│       ├── Models
│       │   └── Todo.swift
│       ├── configure.swift
│       ├── entrypoint.swift
│       └── routes.swift
├── Tests
│   └── AppTests
│       └── AppTests.swift
└── docker-compose.yml
```

这个结构遵循了 Swift 包管理器的标准布局，同时也符合 Vapor 框架的最佳实践。让我们详细解释每个部分：

1. `Dockerfile`：用于构建 Docker 镜像的配置文件。
2. `Package.swift`：Swift 包管理器的配置文件，定义了项目依赖。
3. `Public`：存放静态文件的目录，如 CSS、JavaScript 和图片等。
4. `Sources/App`：存放应用程序的主要源代码。
   - `Controllers`：包含处理请求的控制器。
   - `DTOs`：数据传输对象，用于请求和响应的数据结构。
   - `Migrations`：数据库迁移文件。
   - `Models`：定义数据模型。
   - `configure.swift`：应用程序的配置文件。
   - `entrypoint.swift`：应用程序的入口点。
   - `routes.swift`：定义应用程序的路由。
5. `Tests`：存放测试文件。
6. `docker-compose.yml`：Docker Compose 配置文件，用于定义和运行多容器 Docker 应用程序。

### 示例代码：

以下是一个基本的 `Package.swift` 文件示例：

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MyVaporApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // Vapor 框架依赖
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        // Fluent ORM
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        // PostgreSQL 驱动
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
            ],
            swiftSettings: [
                // 启用测试发现
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

注意事项：
- 确保 `swift-tools-version` 与你使用的 Swift 版本兼容。
- 根据项目需求添加或移除依赖。
- 适当配置 targets，包括主应用程序、可执行文件和测试目标。

## 2. 基础设置

### 2.1 HTTPS 支持

启用 HTTPS 对于保护数据传输安全至关重要。以下是在 Vapor 中配置 HTTPS 的详细说明：

在 `configure.swift` 中添加以下代码：

```swift
import Vapor
import NIOSSL

public func configure(_ app: Application) throws {
    // 其他配置...

    // HTTPS 配置
    try configureTLS(app)
}

private func configureTLS(_ app: Application) throws {
    // 加载证书和私钥
    let cert = try NIOSSLCertificate.fromPEMFile("path/to/cert.pem")
    let key = try NIOSSLPrivateKey.fromPEMFile("path/to/key.pem")

    // 创建 TLS 配置
    let config = TLSConfiguration.makeServerConfiguration(
        certificateChain: cert.map { .certificate($0) },
        privateKey: .privateKey(key)
    )

    // 应用 TLS 配置
    app.http.server.configuration.tlsConfiguration = config
    
    // 设置 HTTPS 端口（默认为 443）
    app.http.server.configuration.port = 443
}
```

注意事项：
- 确保证书和私钥文件路径正确。
- 在生产环境中，建议使用环境变量或安全的密钥管理系统来存储证书和私钥路径。
- 记得配置防火墙允许 443 端口的流量。

### 2.2 统一网关

统一网关可以集中管理 API 路由，便于版本控制和权限管理。以下是实现统一网关的详细步骤：

1. 创建 `APIGateway.swift` 文件：

```swift
import Vapor

struct APIGateway: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        
        // API 版本控制
        let v1 = api.grouped("v1")
        
        // 注册各个模块的路由
        try v1.register(collection: UserController())
        try v1.register(collection: ProductController())
        // ... 注册其他控制器
        
        // 全局中间件
        v1.middleware.use(AuthMiddleware())
        v1.middleware.use(RateLimitMiddleware())
    }
}

// 用户控制器示例
struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
        users.post(use: create)
        users.group(":userID") { user in
            user.get(use: show)
            user.put(use: update)
            user.delete(use: delete)
        }
    }
    
    func index(req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        return user.save(on: req.db).map { user }
    }
    
    func show(req: Request) throws -> EventLoopFuture<User> {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func update(req: Request) throws -> EventLoopFuture<User> {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let updatedUser = try req.content.decode(User.self)
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.name = updatedUser.name
                user.email = updatedUser.email
                return user.save(on: req.db).map { user }
            }
    }
    
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .noContent)
    }
}

// 在 configure.swift 中注册 APIGateway
public func configure(_ app: Application) throws {
    // ... 其他配置
    
    try app.register(collection: APIGateway())
}
```

注意事项：
- 使用版本控制（如 `v1`）可以帮助你在未来进行 API 升级时保持向后兼容性。
- 将相关的路由分组，以保持代码的组织性和可读性。
- 使用中间件来处理跨多个路由的通用逻辑，如认证和限流。
- 确保正确处理错误和边缘情况，如找不到资源时返回适当的 HTTP 状态码。

## 3. 安全性

### 3.1 JWT 认证

JSON Web Token (JWT) 是一种流行的用于身份验证和信息交换的开放标准。以下是在 Vapor 中实现 JWT 认证的详细步骤：

首先，添加 JWT 依赖到你的 `Package.swift` 文件：

```swift
.package(url: "https://github.com/vapor/jwt.git", from: "4.0.0")
```

然后，在 `configure.swift` 中配置 JWT：

```swift
import Vapor
import JWT

public func configure(_ app: Application) throws {
    // ... 其他配置
    
    // JWT 配置
    app.jwt.signers.use(.hs256(key: "your-secret-key"))
}
```

接下来，创建一个 `JWTPayload` 结构体：

```swift
import Vapor
import JWT

struct UserPayload: JWTPayload {
    // JWT 中需要包含的声明
    var sub: SubjectClaim
    var exp: ExpirationClaim
    var iat: IssuedAtClaim
    
    // 自定义字段
    var username: String
    
    init(user: User) throws {
        self.sub = SubjectClaim(value: user.id?.uuidString ?? "")
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(86400)) // 24小时后过期
        self.iat = IssuedAtClaim(value: Date())
        self.username = user.username
    }
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}
```

现在，我们可以实现 JWT 认证中间件：

```swift
import Vapor
import JWT

struct JWTMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard let token = request.headers.bearerAuthorization?.token else {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "Missing authorization token"))
        }
        
        do {
            let payload = try request.jwt.verify(token, as: UserPayload.self)
            request.auth.login(User(id: UUID(payload.sub.value), username: payload.username))
            return next.respond(to: request)
        } catch {
            return request.eventLoop.future(error: Abort(.unauthorized, reason: "Invalid token"))
        }
    }
}
```

最后，在路由中使用 JWT 中间件：

```swift
let protected = app.grouped(JWTMiddleware())
protected.get("me") { req -> String in
    let user = try req.auth.require(User.self)
    return "Hello, \(user.username)!"
}
```

注意事项：
- 在生产环境中，使用强密钥并通过环境变量或安全的密钥管理系统来管理它。
- 定期轮换密钥以提高安全性。
- 考虑实现令牌刷新机制，以允许用户在不重新登录的情况下获取新令牌。
- 在敏感操作中验证令牌的范围（scope）。

### 3.2 认证控制器

认证控制器负责处理用户登录、注册和令牌刷新等操作。以下是一个详细的认证控制器实现：

```swift
import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let authRoutes = routes.grouped("auth")
        authRoutes.post("register", use: register)
        authRoutes.post("login", use: login)
        authRoutes.post("refresh", use: refresh)
        
        let protected = authRoutes.grouped(JWTMiddleware())
        protected.post("logout", use: logout)
    }
    
    func register(req: Request) throws -> EventLoopFuture<TokenResponse> {
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords do not match")
        }
        let user = try User(
            username: create.username,
            passwordHash: Bcrypt.hash(create.password)
        )
        return user.save(on: req.db).flatMap {
            return try login(req: req)
        }
    }
    
    func login(req: Request) throws -> EventLoopFuture<TokenResponse> {
        let login = try req.content.decode(User.Login.self)
        return User.query(on: req.db)
            .filter(\.$username == login.username)
            .first()
            .unwrap(or: Abort(.unauthorized, reason: "Invalid credentials"))
            .flatMap { user in
                do {
                    guard try Bcrypt.verify(login.password, created: user.passwordHash) else {
                        return req.eventLoop.future(error: Abort(.unauthorized, reason: "Invalid credentials"))
                    }
                    let payload = try UserPayload(user: user)
                    return try req.jwt.sign(payload)
                        .map { token in
                            TokenResponse(token: token, user: user)
                        }
                } catch {
                    return req.eventLoop.future(error: error)
                }
            }
    }
    
    func refresh(req: Request) throws -> EventLoopFuture<TokenResponse> {
        let user = try req.auth.require(User.self)
        let payload = try UserPayload(user: user)
        return try req.jwt.sign(payload)
            .map { token in
                TokenResponse(token: token, user: user)
            }
    }
    
    func logout(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        // 在实际应用中，您可能需要实现令牌黑名单或撤销机制
        // 这里我们简单地返回成功状态
        return req.eventLoop.future(.ok)
    }
}

struct TokenResponse: Content {
    let token: String
    let user: User
}

extension User {
    struct Create: Content {
        let username: String
        let password: String
        let confirmPassword: String
    }
    
    struct Login: Content {
        let username: String
        let password: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

// 在 configure.swift 中注册 AuthController
public func configure(_ app: Application) throws {
    // ... 其他配置
    
    try app.register(collection: AuthController())
}

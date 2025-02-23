### 直接回答

- 使用 SwiftUI 开发跨平台 App，需添加 Apple ID 登录功能，登录后才能使用 App，并通过 RevenueCat 实现订阅功能，订阅状态在 iOS 和 macOS 设备间共享。
- Apple ID 登录使用 Authentication Services 框架，RevenueCat 管理订阅，确保用户 ID 一致以共享状态。
- 令人惊讶的是，Apple ID 的“sub”声明可作为跨设备唯一标识符，简化订阅共享。

#### Apple ID 登录实现
通过 SwiftUI 集成 Apple ID 登录，需在 Xcode 中启用“Sign In With Apple”功能，使用 `ASAuthorizationAppleIDButton` 并处理认证流程。iOS 和 macOS 需分别处理呈现锚点，确保跨平台兼容。

#### 订阅功能与共享
使用 RevenueCat 管理订阅，登录后将 Apple ID 的“sub”声明设置为 RevenueCat 用户 ID，确保同一用户在不同设备上的订阅状态一致。需配置 API 密钥并检查订阅状态。

#### 状态管理
根据登录和订阅状态显示不同视图：未登录显示登录视图，登录但无订阅显示订阅视图，有效订阅显示主内容视图。

---

### 技术方案深度调研报告

#### 引言
本文探讨使用 SwiftUI 开发一款同时适用于 iOS 和 macOS 的 App，该 App 需支持 Apple ID 登录，并通过 RevenueCat 实现订阅功能，订阅状态在不同设备间共享。本报告详细分析技术实现方案，提供示例代码，并列出注意事项。

#### Apple ID 登录的实现
Apple ID 登录使用 Authentication Services 框架，需在 Xcode 项目中启用“Sign In With Apple”功能。框架支持 iOS 和 macOS，登录流程通过 `ASAuthorizationAppleIDProvider` 和 `ASAuthorizationController` 完成。

##### 跨平台兼容性
- **iOS 实现**：使用 `UIApplication.shared.window` 作为呈现锚点。
- **macOS 实现**：使用 `NSApplication.shared.mainWindow?.contentView` 作为呈现锚点。
- 为确保跨平台兼容，建议使用条件编译：
  ```swift
  #if os(iOS)
  return UIApplication.shared.window ?? ASPresentationAnchor()
  #else
  return NSApplication.shared.mainWindow?.contentView ?? ASPresentationAnchor()
  #endif
  ```

##### 示例代码
以下为登录视图的实现：
```swift
import SwiftUI
import AuthenticationServices
import RevenueCat

struct LoginView: View {
    @State private var isLoggedIn = false
    @State private var userIdentifier: String?
    
    var body: some View {
        VStack {
            Button("Sign in with Apple") {
                signInWithApple()
            }
        }
    }
    
    func signInWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.performRequests()
        
        controller.presentationContextProvider = self
        controller.completionHandler = { [weak self] auth, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let auth = auth as? ASAuthorizationAppleIDCredential {
                self?.userIdentifier = auth.user
                self?.isLoggedIn = true
                Purchases.shared.setUserID(self?.userIdentifier ?? "")
                checkSubscriptionStatus()
            }
        }
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.customerInfo { customerInfo, error in
            if let error = error {
                print("Error fetching customer info: \(error.localizedDescription)")
                return
            }
            
            if customerInfo?.entitlements["your_entitlement_id"]?.isActive ?? false {
                // 用户有有效订阅，跳转到主内容视图
            } else {
                // 用户无有效订阅，跳转到订阅视图
            }
        }
    }
}

extension LoginView: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.window ?? ASPresentationAnchor()
        #else
        return NSApplication.shared.mainWindow?.contentView ?? ASPresentationAnchor()
        #endif
    }
}
```

#### RevenueCat 订阅功能的集成
RevenueCat 提供跨平台订阅管理，支持 iOS 和 macOS。通过其 Purchases SDK，可简化订阅实现并确保状态共享。

##### 用户 ID 一致性
为实现跨设备订阅共享，需将 Apple ID 登录的“sub”声明（用户唯一标识符）设置为 RevenueCat 的用户 ID。登录后调用 `Purchases.shared.setUserID(userIdentifier)` 确保一致性。

##### SDK 配置
- **安装**：通过 Swift Package Manager 添加 RevenueCat SDK。
- **初始化**：在 App 入口配置 API 密钥：
  ```swift
  @main
  struct MyApp: App {
      init() {
          Purchases.logLevel = .debug
          Purchases.configure(withAPIKey: "your_api_key")
      }
      
      var body: some Scene {
          WindowGroup {
              ContentView()
          }
      }
  }
  ```

##### 订阅状态检查与购买
使用 `customerInfo` 检查订阅状态，示例代码如下：
```swift
Purchases.shared.customerInfo { customerInfo, error in
    if let error = error {
        print("Error fetching customer info: \(error.localizedDescription)")
        return
    }
    
    if customerInfo?.entitlements["your_entitlement_id"]?.isActive ?? false {
        // 用户有有效订阅
    }
}
```
购买订阅时：
```swift
struct SubscriptionView: View {
    var body: some View {
        VStack {
            Text("Please subscribe to continue using the app.")
            Button("Subscribe") {
                subscribe()
            }
        }
    }
    
    func subscribe() {
        Purchases.shared.purchasePackage(byID: "your_package_id") { transaction, customerInfo, error, userCancelled in
            if let error = error {
                print("Error purchasing subscription: \(error.localizedDescription)")
                return
            }
            
            if userCancelled {
                print("User cancelled the purchase")
                return
            }
            
            if let transaction = transaction {
                // 处理交易
            }
            
            if let customerInfo = customerInfo {
                // 更新应用状态
            }
        }
    }
}
```

##### 实时更新
通过通知中心监听订阅状态变化：
```swift
NotificationCenter.default.addObserver(forName: .purchasesCustomerInfoDidChange, object: nil, queue: nil) { _ in
    Purchases.shared.customerInfo { customerInfo, error in
        if let error = error {
            print("Error fetching customer info: \(error.localizedDescription)")
            return
        }
        // 更新应用状态
    }
}
```

#### 状态管理与视图导航
根据登录和订阅状态显示不同视图：
- 未登录：显示 `LoginView`。
- 登录但无有效订阅：显示 `SubscriptionView`。
- 登录且有有效订阅：显示 `MainContentView`。

示例主应用结构：
```swift
@main
struct MyApp: App {
    @State private var isLoggedIn = false
    @State private var hasActiveSubscription = false
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn && hasActiveSubscription {
                MainContentView()
            } else if isLoggedIn {
                SubscriptionView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn, hasActiveSubscription: $hasActiveSubscription)
            }
        }
    }
}
```

#### 注意事项
以下为实施过程中的关键注意事项：

| **类别**            | **注意事项**                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| 平台兼容性          | 确保代码在 iOS 和 macOS 上均可运行，使用条件编译处理平台差异。               |
| 权限与能力          | 在项目设置中启用“Sign In With Apple”及 In-App Purchase 能力。               |
| RevenueCat 配置      | 使用实际 API 密钥和 entitlement ID，定期更新 SDK 以获取最新功能。           |
| 错误处理            | 妥善处理登录和订阅操作中的错误，提升用户体验。                              |
| 用户隐私            | 遵守隐私政策，仅收集必要信息，安全存储用户数据。                            |
| 测试与验证          | 在 iOS 和 macOS 模拟器及真实设备上测试，确保功能正常。                      |
| 本地化              | 使用本地化字符串支持多语言用户界面。                                        |
| 合规性              | 确保符合 App Store 和 Mac App Store 的政策与指南。                          |

#### 结论
通过上述方案，可实现一款支持 Apple ID 登录并共享订阅状态的 SwiftUI App。登录使用 Authentication Services 框架，订阅通过 RevenueCat 管理，跨设备共享依赖于用户 ID 一致性。注意平台差异和合规性，确保用户体验和功能完整性。

#### 关键引用
- [Sign in with Apple on a SwiftUI application](https://www.createwithswift.com/sign-in-with-apple-on-a-swiftui-application/)
- [macOS / Catalyst | In-App Subscriptions Made Easy – RevenueCat](https://www.revenuecat.com/docs/getting-started/installation/macos)


### 用户态持续时间与过期机制

当使用 Apple ID 在 iOS 或 macOS 上登录成功后，用户态的持续时间和过期机制如下：

- **用户态持续时间**：  
  Apple ID 登录后，用户凭证（通常以 token 形式存储）在用户主动退出登录或凭证被撤销前持续有效。Apple 并未公开具体的凭证过期时间，但根据 Apple 的安全策略和行业标准，凭证通常设计为长期有效，以确保用户体验的无缝性。  
  换句话说，在正常情况下，用户态不会因时间因素自动过期，用户无需频繁重新登录。

- **凭证过期机制**：  
  - **自动过期**：Apple ID 凭证通常不会自动过期。用户登录后，凭证会持续有效，直到用户主动退出或凭证因特定原因被撤销。  
  - **凭证撤销**：在以下情况下，凭证可能会失效，用户需要重新登录：  
    - 用户更改了 Apple ID 的密码。  
    - Apple 检测到安全风险，例如账户存在异常活动。  
    在这些情况下，应用会提示用户重新登录以更新凭证。

### 是否需要退出登录 (Logout)

- **用户隐私与控制**：  
  尽管 Apple ID 登录的用户态不会自动过期，但提供退出登录选项是用户隐私和控制的重要体现。用户应有权随时退出登录，以保护其个人信息。  
  因此，应用开发者需要在应用中提供退出登录功能，例如在设置或账户管理页面中添加“退出登录”按钮。

- **退出登录的必要性**：  
  - **隐私保护**：用户可能希望在特定场景下退出登录，例如在共享设备上使用应用时，退出登录可以防止他人访问其账户信息。  
  - **凭证管理**：退出登录后，应用应清除本地存储的用户凭证，并将用户态重置为未登录状态，以确保安全性。  
  - **订阅管理**：如果应用使用 RevenueCat 等工具管理订阅，退出登录时需要调用相关方法（例如 `Purchases.shared.logOut()`）以清除用户的订阅信息，防止后续用户访问到前用户的订阅数据。

- **实现退出登录的建议**：  
  - 在应用中实现退出登录功能时，应清除存储的用户凭证和相关数据。  
  - 退出登录后，应用应更新用户态，显示登录视图或提示用户重新登录。

### 结论

- Apple ID 登录的用户态在用户主动退出或凭证被撤销前持续有效，通常不会因时间因素自动过期。  
- 虽然用户态不会自动过期，但为了增强用户隐私和安全性，应用开发者需要提供退出登录选项，并妥善管理用户凭证和订阅信息。  
- 用户在特定场景下（如共享设备、隐私需求）可能需要退出登录，因此退出登录功能是应用设计中不可或缺的一部分。


### 如何通过 App Store 审核：Apple ID 登录功能的要求

当您的 App 包含 Apple ID 登录功能时，无论是针对 iOS 还是 macOS，提交到 App Store 审核时都需要满足一些关键要求，以确保顺利通过审核。以下是详细的共性要求及建议，这些要求适用于 iOS 和 macOS 平台，因平台差异而异的部分较少，因此主要聚焦共性要求。

---

#### 1. **提供完整的文档和测试账号**
   - **要求**：您必须为审核人员提供详细的文档，说明如何使用 Apple ID 登录功能，并附上一个测试账号（包括用户名和密码），以便审核人员能够顺利登录并测试 App 的功能。
   - **原因**：App Store 审核指南明确规定，所有包含登录功能的 App 都需要提供测试账号和相关文档，以便审核人员验证功能的完整性。
   - **建议**：在提交审核时，文档应简洁明了，包括登录步骤、测试账号信息以及如何访问 App 的主要功能。确保测试账号有效且与 App 的登录系统兼容。

---

#### 2. **遵守 Apple 的隐私政策**
   - **要求**：App 必须严格遵守 Apple 的隐私政策，特别是关于用户数据的收集、使用和保护。App 不得收集或存储用户的 Apple ID 或密码，也不得将用户的 Apple ID 与其他服务关联。
   - **原因**：Apple 对用户隐私保护极为重视，任何违反隐私政策的行为都可能导致审核被拒。
   - **建议**：使用 Apple 提供的 Sign in with Apple API 进行登录，避免直接处理用户敏感信息，并确保在 App 的隐私政策中清晰说明数据用途。

---

#### 3. **提供退出登录功能**
   - **要求**：App 必须提供一种方式让用户能够退出登录，确保用户可以随时结束会话。
   - **原因**：用户对账户的控制权是 Apple 审核的重要考量，提供退出登录功能是隐私保护和用户体验的基本要求。
   - **建议**：在 App 的设置或账户管理页面中添加“退出登录”选项，并确保退出后用户无法访问受保护的内容。

---

#### 4. **确保 Apple ID 登录功能正确集成并经过测试**
   - **要求**：App 必须正确集成 Apple ID 登录功能，并确保该功能在提交审核前已在 iOS 和 macOS 上充分测试且正常运行。
   - **原因**：审核人员会测试 App 在不同平台上的表现，以确保功能一致性和稳定性。
   - **建议**：在提交前，测试 App 在多种设备（如 iPhone、iPad、Mac）及操作系统版本上的登录功能，确保兼容性和稳定性。

---

#### 5. **符合 App Store 的其他审核要求**
   - **要求**：App 必须遵守 App Store 的所有审核指南，包括内容政策、性能要求和法律合规性。
   - **原因**：Apple 对 App 的整体质量和合规性有严格标准，任何违规内容或技术问题都可能导致审核失败。
   - **建议**：仔细查阅最新的 App Store 审核指南，确保 App 不包含违规内容（如未经授权的代码或功能），并修复所有已知的 bug，提升 App 的稳定性。

---

### 针对 iOS 和 macOS 的补充说明
上述要求为 iOS 和 macOS 的共性要求，因为 Apple ID 登录功能基于统一的 Sign in with Apple API，跨平台实现方式一致。以下是针对平台的微小差异建议：
- **iOS**：重点测试不同 iPhone 和 iPad 型号的适配性，确保触摸交互和界面布局无误。
- **macOS**：额外关注键盘和鼠标操作的兼容性，确保登录界面在桌面环境下的体验良好。

但总体而言，由于 Apple ID 登录功能的实现依赖同一套 API 和政策，iOS 和 macOS 的审核要求高度一致，无需特别区分。

---

### 总结
要通过 App Store 审核，带有 Apple ID 登录功能的 App 至少需要满足以下共性要求：
1. 提供详细的文档和测试账号。
2. 严格遵守 Apple 的隐私政策。
3. 提供退出登录功能。
4. 确保登录功能正确集成并经过充分测试。
5. 符合 App Store 的其他审核标准。

在提交审核前，请确保准备充分，包括清晰的文档、有效的测试账号以及全面的功能测试。通过这些步骤，您的 App 将更有机会顺利通过审核并成功上架。


在开发适用于 iOS 和 macOS 的 App 时，维护用户的登录状态并妥善处理用户登出操作是确保用户体验和数据安全的关键。以下将详细说明如何在用户登录成功后维护登录态，如何在用户再次打开 App 时判断用户已登录，以及用户登出时需要执行的清理和后续工作。

---

## 1. 维护用户登录态

### 方案概述
用户登录成功后，App 需要保存用户的登录凭证，以便在用户再次打开 App 时能够识别其登录状态。通常，登录凭证可以是服务器返回的 token 或用户 ID，这些信息需要安全地存储在设备上，并在 App 启动时进行检查。

### iOS 和 macOS 共性方案
- **存储登录凭证**：
  - **Keychain**：Apple 平台提供的安全存储工具，适用于存储敏感信息（如 token），支持 iOS 和 macOS。它提供加密存储和访问控制，确保数据安全。
  - **UserDefaults**：适用于存储非敏感信息（如用户 ID），在 iOS 上使用 `UserDefaults`，在 macOS 上使用 `NSUserDefaults`。
- **判断登录状态**：
  - App 启动时，检查 Keychain 中是否存在有效的登录凭证（如 token）。
  - 如果凭证存在且未过期，则认为用户已登录成功，直接进入 App 主界面。
  - 如果凭证不存在或已过期，则引导用户重新登录。

### 示例代码
以下是使用 Swift 在 iOS 和 macOS 上存储和读取登录 token 的实现：

#### 保存登录 token 到 Keychain
```swift
import Security
import Foundation

func saveTokenToKeychain(token: String) {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "userToken",
        kSecValueData as String: token.data(using: .utf8)!
    ]
    SecItemDelete(keychainQuery as CFDictionary) // 先删除旧 token
    SecItemAdd(keychainQuery as CFDictionary, nil)
}
```

#### 从 Keychain 读取登录 token
```swift
func getTokenFromKeychain() -> String? {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "userToken",
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
    if status == errSecSuccess, let data = dataTypeRef as? Data {
        return String(data: data, encoding: .utf8)
    }
    return nil
}
```

#### 判断用户是否已登录
在 App 启动时（例如在 `AppDelegate` 或 `SceneDelegate` 中）检查登录状态：
```swift
if let token = getTokenFromKeychain(), !token.isEmpty {
    // 用户已登录，进入主界面
    // 可进一步验证 token 是否过期（视后端要求）
} else {
    // 用户未登录，显示登录界面
}
```

### 平台特定注意事项
- **iOS**：Keychain 使用简单直接，通常无需额外配置。
- **macOS**：Keychain 可能需要用户授权访问，特别是在首次使用时。确保 App 有权限访问 Keychain，并处理可能的授权请求。

---

## 2. 用户登出处理

### 方案概述
当用户选择登出时，App 需要清理所有与登录状态相关的数据，确保用户无法访问受保护的内容，并将用户引导回登录界面。

### iOS 和 macOS 共性方案
- **清理登录凭证**：
  - 从 Keychain 中删除存储的 token。
  - 从 UserDefaults 中删除非敏感的登录状态信息（如用户 ID）。
- **清理其他用户数据**：
  - 根据 App 需求，清理本地缓存、数据库或文件系统中与用户相关的数据（如用户偏好设置、临时文件等）。
- **后续工作**：
  - 更新应用状态，重置为未登录。
  - 将用户界面切换回登录视图。

### 示例代码
以下是登出时清理登录凭证的实现：

#### 删除 Keychain 中的 token
```swift
func deleteTokenFromKeychain() {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "userToken"
    ]
    SecItemDelete(keychainQuery as CFDictionary)
}
```

#### 删除 UserDefaults 中的用户 ID
```swift
func deleteUserIDFromUserDefaults() {
    UserDefaults.standard.removeObject(forKey: "userID")
}
```

#### 完整登出函数
```swift
func logout() {
    deleteTokenFromKeychain()              // 清理 Keychain 中的 token
    deleteUserIDFromUserDefaults()         // 清理 UserDefaults 中的用户 ID
    // 清理其他用户数据（视需求）
    // 例如：FileManager.default.removeItem(at: cacheDirectory)
    // 更新应用状态，显示登录视图
}
```

### 平台特定注意事项
- **macOS**：如果 UserDefaults 与 iCloud 同步，需确保登出时清理的数据不会通过 iCloud 恢复。
- **iOS**：清理操作通常较为简单，但需确保所有本地缓存都被清除。

---

## 3. 安全性和用户体验

### 安全性
- **使用 Keychain 存储敏感信息**：避免将 token 等敏感数据存储在 UserDefaults 中，确保数据加密存储。
- **遵守隐私政策**：不存储用户的 Apple ID 或密码，仅保存必要的登录凭证。
- **彻底清理数据**：登出时，确保所有用户相关数据都被删除，防止数据泄露。

### 用户体验
- **提供明确的登出选项**：在 App 的设置或账户页面中添加“退出登录”按钮。
- **登出后重置状态**：确保用户登出后无法访问受保护的内容，并被引导回登录界面。
- **处理 token 过期**：如果后端 token 有有效期，App 需在 token 过期时检测并要求用户重新登录。

---

## 结论
- **维护登录态**：使用 Keychain 安全存储登录凭证（如 token），App 启动时检查凭证是否存在且有效。
- **判断已登录**：通过读取 Keychain 中的 token 并验证其有效性，决定是否直接进入主界面。
- **用户登出**：清理 Keychain 和 UserDefaults 中的登录凭证，视需求清理其他用户数据，并将用户引导回登录界面。

通过以上方案，您的 App 能够在 iOS 和 macOS 上有效维护用户登录状态，并在用户登出时完成必要的清理工作，确保用户体验和数据安全。

您好！根据您的需求，我们将调整方案，在 macOS 下使用 `UserDefaults` 存储登录 token，而不是 Keychain，以避免 Keychain 的授权流程带来的复杂性。以下是调整后的方案说明和实现方式。

---

### 方案调整说明
- **iOS 平台**：继续使用 Keychain 存储 token，以确保敏感数据的安全性。
- **macOS 平台**：使用 `UserDefaults` 存储 token，简化用户体验，避免 Keychain 的授权流程。
- **共性**：登录和登出逻辑保持一致，仅存储方式根据平台不同而有所调整。

---

### 功能实现
以下是调整后的具体实现，涵盖登录功能、token 存储和读取逻辑。

#### 1. 登录视图
使用 SwiftUI 实现登录界面，登录按钮通过 `ASAuthorizationAppleIDButton` 触发 Apple ID 授权请求。

```swift
import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var isLoggedIn = false
    
    var body: some View {
        VStack {
            if isLoggedIn {
                Text("已登录")
                Button("登出") {
                    logout()
                }
            } else {
                SignInWithAppleButton()
                    .frame(width: 280, height: 45)
                    .onTapGesture {
                        signInWithApple()
                    }
            }
        }
        .onAppear {
            checkLoginStatus()
        }
    }
    
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func checkLoginStatus() {
        if let token = getToken(), !token.isEmpty {
            isLoggedIn = true
        }
    }
    
    func logout() {
        deleteToken()
        isLoggedIn = false
    }
}

extension LoginView: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let token = appleIDCredential.identityToken?.base64EncodedString() ?? ""
            saveToken(token: token)
            isLoggedIn = true
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("登录失败: \(error.localizedDescription)")
    }
}

extension LoginView: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.windows.first!
        #else
        return NSApplication.shared.mainWindow!
        #endif
    }
}
```

#### 2. 存储和读取 token
根据平台不同，使用 Keychain（iOS）或 `UserDefaults`（macOS）存储 token。

```swift
import Foundation
import Security

// 保存 token
func saveToken(token: String) {
    #if os(iOS)
    saveTokenToKeychain(token: token)
    #else
    saveTokenToUserDefaults(token: token)
    #endif
}

// 读取 token
func getToken() -> String? {
    #if os(iOS)
    return getTokenFromKeychain()
    #else
    return getTokenFromUserDefaults()
    #endif
}

// 删除 token
func deleteToken() {
    #if os(iOS)
    deleteTokenFromKeychain()
    #else
    deleteTokenFromUserDefaults()
    #endif
}

// iOS: Keychain 操作
func saveTokenToKeychain(token: String) {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "appleIDToken",
        kSecValueData as String: token.data(using: .utf8)!
    ]
    SecItemDelete(keychainQuery as CFDictionary)
    SecItemAdd(keychainQuery as CFDictionary, nil)
}

func getTokenFromKeychain() -> String? {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "appleIDToken",
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)
    if status == errSecSuccess, let data = dataTypeRef as? Data {
        return String(data: data, encoding: .utf8)
    }
    return nil
}

func deleteTokenFromKeychain() {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "appleIDToken"
    ]
    SecItemDelete(keychainQuery as CFDictionary)
}

// macOS: UserDefaults 操作
func saveTokenToUserDefaults(token: String) {
    UserDefaults.standard.set(token, forKey: "appleIDToken")
}

func getTokenFromUserDefaults() -> String? {
    return UserDefaults.standard.string(forKey: "appleIDToken")
}

func deleteTokenFromUserDefaults() {
    UserDefaults.standard.removeObject(forKey: "appleIDToken")
}
```

---

### 功能说明
- **登录按钮**：使用 `ASAuthorizationAppleIDButton` 作为登录按钮，点击后触发 Apple ID 授权请求。
- **存储 token**：
  - 在 iOS 上，使用 Keychain 存储 token，确保安全性。
  - 在 macOS 上，使用 `UserDefaults` 存储 token，简化操作。
- **判断登录状态**：App 启动时，根据平台读取 token，判断用户是否已登录。
- **登出功能**：清理 token（iOS: Keychain, macOS: UserDefaults），并重置登录状态。

---

### 注意事项
1. **安全性**：在 macOS 上使用 `UserDefaults` 存储 token 较为简单，但相比 Keychain，安全性较低。建议仅在非敏感场景下使用。
2. **平台适配**：通过 `#if os(iOS)` 和 `#else` 区分平台，确保代码在 iOS 和 macOS 上均能正常运行。
3. **用户体验**：在 macOS 上，避免了 Keychain 的授权流程，简化了用户操作。

这样调整后，您的 App 在 macOS 上使用 `UserDefaults` 存储 token，满足了您的需求，同时在 iOS 上继续使用 Keychain 确保安全性。
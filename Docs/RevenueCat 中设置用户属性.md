### 关键要点

- 研究表明，可以通过 RevenueCat SDK 在 macOS 应用中设置用户属性来携带设备基本信息。
- 证据倾向于在订阅事件中包含这些属性，从而在 RevenueCat 平台上查看订阅日志。
- 建议生成一个唯一的支持 ID 并显示给用户，以方便定位问题。

### 技术方案概述

**收集设备信息**  
在 macOS 应用中，使用 Swift 收集设备型号、操作系统版本和应用版本等信息。例如，通过 `sysctlbyname` 获取设备型号，`ProcessInfo.processInfo.operatingSystemVersionString` 获取 OS 版本，`Bundle.main.infoDictionary` 获取应用版本。

**设置 RevenueCat 属性**  
使用 RevenueCat SDK 的 `setAttributes` 方法，将设备信息设置为用户属性。建议同时生成一个唯一的支持 ID（如 UUID），并设置为属性。例如：

```swift
Purchases.shared.attribution.setAttributes([
    "device_model": getDeviceModel(),
    "os_version": osVersion,
    "app_version": appVersion,
    "support_id": UUID().uuidString
])
```

确保在订阅前设置这些属性。

**显示支持 ID**  
在应用 UI（如设置页面）中显示支持 ID，方便用户在报告问题时提供。

**定位订阅日志**  
当用户报告问题时，请求他们提供支持 ID。在 RevenueCat 仪表板中，查找具有匹配支持 ID 属性的客户，然后查看其订阅事件以诊断问题。

**注意事项**  

- 确保属性在订阅前设置，以包含在事件中。
- 属性键长不超过 40 字符，值长不超过 500 字符，每用户最多 50 个唯一属性。
- 避免在属性中包含敏感数据。
- 如果用户重新安装应用，支持 ID 可能改变，需注意。

---

### 详细技术调研报告

#### 引言

本文探讨如何在 macOS 应用中使用 RevenueCat 搭建 IAP（应用内购买）时，在用户订阅时携带设备基本信息，并确保这些信息可在 RevenueCat 平台的订阅日志中查看。这样，当用户订阅出现问题时，可以通过设备信息定位到用户的订阅流水日志。本报告提供了详细的技术方案和注意事项，基于 2025 年 4 月 6 日的最新研究。

#### 背景与需求分析

RevenueCat 是一个跨平台的应用内订阅管理服务，支持 iOS 和 macOS 等平台。通过其 SDK，开发者可以处理与 Apple StoreKit 的交互，管理订阅状态。用户的需求是：在订阅过程中，携带设备基本信息（如设备型号、OS 版本、应用版本），并在 RevenueCat 平台上查看这些信息，以便在订阅问题发生时快速定位用户。

#### 技术方案

##### 1. 设备信息的收集

在 macOS 应用中，需要收集设备的基本信息。这些信息应是非敏感的，且能帮助识别设备。以下是实现方式：

- **设备型号**：使用 `sysctlbyname` 获取硬件型号。例如：

  ```swift
  import Foundation

  func getDeviceModel() -> String {
      var size = 0
      sysctlbyname("hw.model", nil, &size, nil, 0)
      var machine = [CChar](repeating: 0, count: size)
      sysctlbyname("hw.model", &machine, &size, nil, 0)
      return String(cString: machine)
  }
  ```

  这将返回类似 "MacBookPro16,1" 的信息。

- **操作系统版本**：使用 `ProcessInfo.processInfo.operatingSystemVersionString` 获取，例如 "macOS 12.3"。

- **应用版本**：从应用包信息中获取，使用 `Bundle.main.infoDictionary?["CFBundleShortVersionString"]`：

  ```swift
  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  ```

这些信息应在应用启动时或用户准备订阅前收集。

##### 2. 在 RevenueCat 中设置用户属性

RevenueCat 允许开发者为用户设置自定义属性，这些属性可以与用户关联，并包含在订阅事件中。根据文档 [Setting Attributes | In-App Subscriptions Made Easy – RevenueCat](https://www.revenuecat.com/docs/customers/customer-attributes)，可以通过 SDK 的 `setAttributes` 方法设置属性。例如：

```swift
Purchases.shared.attribution.setAttributes([
    "device_model": getDeviceModel(),
    "os_version": osVersion,
    "app_version": appVersion
])
```

此外，建议生成一个唯一的支持 ID（如 UUID），并设置为属性，以方便后续定位用户：

```swift
let supportID = UUID().uuidString
Purchases.shared.attribution.setAttributes(["support_id": supportID])
```

**属性限制**：

- 每个用户最多 50 个唯一属性。
- 属性键长不超过 40 字符，值长不超过 500 字符。
- 键不得以 `$` 开头，不得包含空白字符，仅允许字母数字、`-` 和 `_`。

**属性同步**：属性默认在以下情况下同步：

- `Purchases.configure()` 调用时。
- 应用进入后台/前台时。
- 购买或恢复操作时。
如需立即同步，可调用 `syncAttributesAndOfferingsIfNeeded()`，尤其在需要用于 Targeting 时。

##### 3. 确保属性包含在订阅事件中

根据研究，RevenueCat 的订阅事件（如 INITIAL_PURCHASE、RENEWAL 等）会包含用户的当前属性。例如，在 webhook 事件中，`subscriber_attributes` 字段会包含所有设置的属性 [Event Types and Fields | In-App Subscriptions Made Easy – RevenueCat](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)。因此，只要在订阅前设置属性，这些信息将出现在事件数据中，并在仪表板中可见。

##### 4. 显示支持 ID 以便用户提供

为方便定位，建议在应用 UI 中显示支持 ID，例如在设置页面或关于页面。用户可以在报告问题时提供此 ID。例如：

- 生成支持 ID：`let supportID = UUID().uuidString`。
- 存储在 `UserDefaults` 中以确保持久性。
- 在 UI 中显示：例如，标签显示 "支持 ID: \(supportID)"。

##### 5. 在 RevenueCat 仪表板中定位用户

当用户报告订阅问题时，请求他们提供支持 ID。在 RevenueCat 仪表板中：

- 导航到客户列表，查看每个客户的属性。
- 查找具有匹配支持 ID 属性的客户。
- 查看该客户的订阅事件历史，以诊断问题。

**搜索限制**：根据 2023 年的社区帖子 [Search for user using attributes | RevenueCat Community](https://community.revenuecat.com/dashboard-tools-52/search-for-user-using-attributes-2492)，仪表板可能不支持直接按属性搜索。但可以通过手动查看客户列表，结合属性过滤找到匹配的用户。考虑到当前时间（2025 年 4 月 6 日），RevenueCat 可能已改进此功能，建议检查最新仪表板功能。

##### 6. 使用 API 进行高级查询（可选）

如果仪表板搜索不足，可使用 RevenueCat REST API 读取客户信息。例如，文档提到可以通过 `POST /subscribers/{app_user_id}/attributes` 设置属性，也可通过 API 获取客户数据 [Setting Attributes | In-App Subscriptions Made Easy – RevenueCat](https://www.revenuecat.com/docs/customers/customer-attributes)。但直接按属性查询所有客户可能需要遍历所有客户，效率较低，适合小规模应用。

#### 注意事项

1. **属性设置时机**  
   确保在订阅前设置属性，以保证包含在事件中。建议在应用启动时或用户登录时设置，并在购买前调用 `syncAttributesAndOfferingsIfNeeded()` 以确保同步。

2. **数据安全**  
   属性不安全，文档明确建议避免存储敏感数据（如订阅状态）。确保收集的设备信息（如型号、版本）不涉及隐私。

3. **属性限制**  
   - 键长不超过 40 字符，值长不超过 500 字符。
   - 每个用户最多 50 个唯一属性。
   - 键不得以 `$` 开头，不得包含空白字符，仅允许字母数字、`-` 和 `_`。

4. **支持 ID 的持久性**  
   如果用户重新安装应用，支持 ID 可能改变。建议存储在 `UserDefaults` 或其他持久化存储中，但需注意 macOS 用户可能较少重新安装，影响较小。

5. **规模与效率**  
   如果客户数量庞大，手动查找属性匹配可能效率低下。考虑使用 API 或设置 webhook 将事件数据同步到自建服务器进行查询。

#### 总结

通过在 RevenueCat 中设置设备信息和支持 ID 作为用户属性，并确保这些属性包含在订阅事件中，可以实现需求。当用户报告问题时，通过支持 ID 快速定位客户，并查看其订阅日志进行诊断。注意属性设置时机和数据安全，确保方案可行。

#### 关键引用

- [Setting Attributes In-App Subscriptions Made Easy – RevenueCat](https://www.revenuecat.com/docs/customers/customer-attributes)
- [Event Types and Fields In-App Subscriptions Made Easy – RevenueCat](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)
- [Search for user using attributes RevenueCat Community](https://community.revenuecat.com/dashboard-tools-52/search-for-user-using-attributes-2492)
- [Customers in RevenueCat In-App Subscriptions Made Easy – RevenueCat](https://www.revenuecat.com/docs/customers/user-ids)

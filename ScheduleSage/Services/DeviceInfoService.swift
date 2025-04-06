//
//  DeviceInfoService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-04-07.
//

import Foundation
import IOKit

/// 设备信息服务
/// 提供获取当前设备基本信息的方法，用于用户支持和问题排查
struct DeviceInfoService {

  /// 获取设备型号标识符
  /// - Returns: 设备型号标识符，如 "MacBookPro16,1"
  static func getDeviceModel() -> String {
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &machine, &size, nil, 0)
    return String(cString: machine)
  }

  /// 获取操作系统版本
  /// - Returns: 操作系统版本字符串，如 "macOS 14.0"
  static func getOSVersion() -> String {
    return ProcessInfo.processInfo.operatingSystemVersionString
  }

  /// 获取应用版本
  /// - Returns: 应用版本号，如 "1.0.0"
  static func getAppVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }

  /// 获取应用构建版本
  /// - Returns: 应用构建版本号，如 "42"
  static func getAppBuildNumber() -> String {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
  }

  /// 获取设备硬件UUID
  /// - Returns: 设备唯一的硬件UUID标识符
  static func getHardwareID() -> String {
    var masterPort: mach_port_t = 0
    var ioKit = IOMasterPort(mach_port_t(MACH_PORT_NULL), &masterPort)

    var platformExpert: io_service_t = 0
    var hardwareUUID: String = "Unknown"

    platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

    if platformExpert != 0 {
      let hardwareUUIDAsCFString = IORegistryEntryCreateCFProperty(
        platformExpert,
        "IOPlatformUUID" as CFString,
        kCFAllocatorDefault,
        0
      )

      if let hardwareUUIDAsCFString = hardwareUUIDAsCFString?.takeUnretainedValue() as? String {
        hardwareUUID = hardwareUUIDAsCFString
      }

      IOObjectRelease(platformExpert)
    }

    return hardwareUUID
  }

  /// 获取设备序列号
  /// - Returns: 系统序列号
  static func getSerialNumber() -> String {
    var platformExpert: io_service_t = 0
    var serialNumber: String = "Unknown"

    platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

    if platformExpert != 0 {
      let serialNumberAsCFString = IORegistryEntryCreateCFProperty(
        platformExpert,
        "IOPlatformSerialNumber" as CFString,
        kCFAllocatorDefault,
        0
      )

      if let serialNumberAsCFString = serialNumberAsCFString?.takeUnretainedValue() as? String {
        serialNumber = serialNumberAsCFString
      }

      IOObjectRelease(platformExpert)
    }

    // 对序列号进行部分掩盖处理，保护用户隐私，同时保留足够的信息用于支持
    // 仅保留前4位和后4位，中间用星号替代
    if serialNumber.count > 8 {
      let prefix = String(serialNumber.prefix(4))
      let suffix = String(serialNumber.suffix(4))
      let maskedPart = String(repeating: "*", count: serialNumber.count - 8)
      return "\(prefix)\(maskedPart)\(suffix)"
    } else if serialNumber.count > 4 {
      // 如果长度不足8位但大于4位，则只显示前两位和后两位
      let prefix = String(serialNumber.prefix(2))
      let suffix = String(serialNumber.suffix(2))
      let maskedPart = String(repeating: "*", count: serialNumber.count - 4)
      return "\(prefix)\(maskedPart)\(suffix)"
    }

    return serialNumber
  }

  /// 生成唯一的支持ID
  /// 首次生成后会保存在UserDefaults中以保持持久性
  /// - Returns: 用于客服支持的唯一标识符
  static func getSupportID() -> String {
    let defaults = UserDefaults.standard
    let supportIDKey = "com.tiwenlab.schedulesage.supportID"

    if let existingID = defaults.string(forKey: supportIDKey) {
      return existingID
    }

    let newID = UUID().uuidString
    defaults.set(newID, forKey: supportIDKey)
    return newID
  }

  /// 获取设备的完整信息字典
  /// - Returns: 包含所有设备信息的字典
  static func getDeviceInfoDictionary() -> [String: String] {
    return [
      "device_model": getDeviceModel(),
      "os_version": getOSVersion(),
      "app_version": getAppVersion(),
      "build_number": getAppBuildNumber(),
      "support_id": getSupportID(),
      "hardware_id": getHardwareID(),
      "serial_number": getSerialNumber(),
    ]
  }
}

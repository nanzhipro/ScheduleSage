//
//  DeviceAccessService.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-10-01.
//

import Alamofire
import Foundation
import IOKit
import ScheduleSage

/// Device Premium Access Control Service
/// Responsible for communicating with the server to verify if a device has access to premium features
actor DeviceAccessService {
  // MARK: - Properties
  private let logger: LoggerService
  private let apiConfig: APIConfig
  private let userDefaults = UserDefaults.standard

  // Storage keys
  private let accessStatusKey = "premium_access_status"
  private let lastCheckTimeKey = "premium_last_check_time"
  private let deviceUUIDKey = "device_uuid_key"

  // Check interval (default 24 hours)
//  private let checkInterval: TimeInterval = 86400
    private let checkInterval: TimeInterval = 10

  // MARK: - Initialization
  init(
    logger: LoggerService = .makeCompatible(category: "DeviceAccessService"),
    apiConfig: APIConfig = .shared
  ) {
    self.logger = logger
    self.apiConfig = apiConfig
  }

  // MARK: - Public Interface

  /// Checks if the device has access to premium features
  /// - Parameter force: Whether to force a network request, ignoring cache
  /// - Returns: Whether the device has access to premium features
  func checkPremiumAccess(force: Bool = false) async -> Bool {
    logger.info("Checking device premium access, force refresh: \(force)")

    let lastCheckTime = userDefaults.double(forKey: lastCheckTimeKey)
    let currentTime = Date().timeIntervalSince1970

    // If forcing a check or last check was too long ago, perform network request
    if force || currentTime - lastCheckTime > checkInterval {
      logger.info("Network request needed to check access rights")
      return await requestPremiumAccess()
    } else {
      // Otherwise use cached result
      let hasAccess = userDefaults.bool(forKey: accessStatusKey)
      logger.info("Using cached access result: \(hasAccess)")
      return hasAccess
    }
  }

  /// Resets cached status, forcing next check to perform a network request
  func resetCachedStatus() {
    logger.info("Resetting device access cache status")
    userDefaults.removeObject(forKey: lastCheckTimeKey)
  }

  // MARK: - Private Methods

  /// Sends network request to check access rights
  private func requestPremiumAccess() async -> Bool {
    do {
      // Ensure token is initialized
      try await apiConfig.ensureTokenInitialized()

      let deviceUUID = getDeviceUUID()
      logger.info("Sending device access check request, device ID: \(deviceUUID)")

      let endpoint = DeviceAccessEndpoint.checkAccess(deviceUUID: deviceUUID)
      let result: Result<DeviceAccessResponse, APIError> = await APIClient.shared.request(endpoint)

      switch result {
      case .success(let response):
        logger.info(
          "Device access check response: hasAccess=\(response.hasAccess), reason=\(response.reason ?? "none")"
        )

        // Update cache
        userDefaults.set(response.hasAccess, forKey: accessStatusKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastCheckTimeKey)

        return response.hasAccess

      case .failure(let error):
        logger.error("Device access check failed: \(error.localizedDescription)")
        return cachedAccessStatusOrDefault(defaultValue: false)
      }
    } catch {
      logger.error("Device access check exception: \(error.localizedDescription)")
      return cachedAccessStatusOrDefault(defaultValue: false)
    }
  }

  /// Returns cached access status if available, otherwise returns the default value
  private func cachedAccessStatusOrDefault(defaultValue: Bool) -> Bool {
    userDefaults.object(forKey: accessStatusKey) != nil
      ? userDefaults.bool(forKey: accessStatusKey)
      : defaultValue
  }

  /// Gets the device UUID
  private func getDeviceUUID() -> String {
    // If already have a stored UUID, use it
    if let savedUUID = userDefaults.string(forKey: deviceUUIDKey) {
      return savedUUID
    }

    // Use DeviceInfoService to get device hardware UUID
    let deviceUUID = DeviceInfoService.getHardwareID()
    logger.info("Retrieved device hardware ID: \(deviceUUID)")

    // Store UUID for future use
    userDefaults.set(deviceUUID, forKey: deviceUUIDKey)

    return deviceUUID
  }
}

// MARK: - Models
struct DeviceAccessResponse: Codable {
  let hasAccess: Bool
  let reason: String?
}

// MARK: - Endpoint
private enum DeviceAccessEndpoint: Endpoint {
  case checkAccess(deviceUUID: String)

  var path: String {
    switch self {
    case .checkAccess:
      return "/api/v1/premium-features/check-access"
    }
  }

  var method: HTTPMethod { .post }

  var encoding: ParameterEncoding {
    JSONEncoding.default
  }

  var parameters: Parameters? {
    switch self {
    case .checkAccess(let deviceUUID):
      return ["deviceUUID": deviceUUID]
    }
  }
}

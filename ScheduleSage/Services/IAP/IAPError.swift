//
//  IAPError.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import Foundation

enum IAPError: LocalizedError {
    case purchaseFailed
    case restoreFailed
    case networkError
    case userCancelled
    case productNotFound
    case platformNotSupported
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed:
            return NSLocalizedString("purchase_failed", comment: "")
        case .restoreFailed:
            return NSLocalizedString("restore_failed", comment: "")
        case .networkError:
            return NSLocalizedString("network_error", comment: "")
        case .userCancelled:
            return NSLocalizedString("user_cancelled", comment: "")
        case .productNotFound:
            return NSLocalizedString("product_not_found", comment: "")
        case .platformNotSupported:
            #if os(iOS)
            return NSLocalizedString("feature_not_supported_ios", comment: "")
            #else
            return NSLocalizedString("feature_not_supported_macos", comment: "")
            #endif
        }
    }
} 
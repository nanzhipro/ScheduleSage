//
//  IAPError.swift
//  ScheduleSage
//
//  Created by CursorAI on 2024-03-14.
//

import Foundation

enum IAPError: Error {
    case configurationFailed
    case purchaseFailed
    case restoreFailed
    case userCancelled
    case productNotFound
    case networkError
    case invalidPurchase
    case platformNotSupported
    case paymentPending
    case configurationError
    case storeProblem
    case storeNotAvailable
    case storeAuthError
    
    var localizedDescription: String {
        switch self {
        case .configurationFailed:
            return NSLocalizedString("iap.error.configuration_failed", comment: "")
        case .purchaseFailed:
            return NSLocalizedString("iap.error.purchase_failed", comment: "")
        case .restoreFailed:
            return NSLocalizedString("iap.error.restore_failed", comment: "")
        case .userCancelled:
            return NSLocalizedString("iap.error.user_cancelled", comment: "")
        case .productNotFound:
            return NSLocalizedString("iap.error.product_not_found", comment: "")
        case .networkError:
            return NSLocalizedString("iap.error.network_error", comment: "")
        case .invalidPurchase:
            return NSLocalizedString("iap.error.invalid_purchase", comment: "")
        case .platformNotSupported:
            return NSLocalizedString("error.iap.platform_not_supported", comment: "")
        case .paymentPending:
            return NSLocalizedString("error.iap.payment_pending", comment: "")
        case .configurationError:
            return NSLocalizedString("error.iap.configuration_error", comment: "")
        case .storeProblem:
            return NSLocalizedString("error.iap.store_problem", comment: "")
        case .storeNotAvailable:
            return NSLocalizedString("error.iap.store_not_available", comment: "")
        case .storeAuthError:
            return NSLocalizedString("error.iap.store_auth_error", comment: "")
        }
    }
} 
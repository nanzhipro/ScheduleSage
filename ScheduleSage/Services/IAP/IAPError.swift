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
    case paymentPending
    case configurationError
    case storeProblem
    case storeNotAvailable
    case storeAuthError
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed:
            return NSLocalizedString("error.iap.purchase_failed", comment: "")
        case .restoreFailed:
            return NSLocalizedString("error.iap.restore_failed", comment: "")
        case .networkError:
            return NSLocalizedString("error.iap.network_error", comment: "")
        case .userCancelled:
            return NSLocalizedString("error.iap.user_cancelled", comment: "")
        case .productNotFound:
            return NSLocalizedString("error.iap.product_not_found", comment: "")
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
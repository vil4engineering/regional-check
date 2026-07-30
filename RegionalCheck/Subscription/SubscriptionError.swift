import Foundation

enum SubscriptionError: Error, Equatable, LocalizedError {
    case productUnavailable
    case verificationFailed
    case purchaseFailed(String)
    case offline

    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            String(localized: "subscription.error.unavailable")
        case .verificationFailed:
            String(localized: "subscription.error.verification")
        case let .purchaseFailed(message):
            message
        case .offline:
            String(localized: "subscription.error.offline")
        }
    }
}

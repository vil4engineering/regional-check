import Foundation

enum StoreKitPurchaseVerification {
    static func handleSuccess(
        isVerified: Bool,
        finish: () async -> Void
    ) async -> PurchaseResult {
        await finish()
        guard isVerified else {
            return .failed(String(localized: "subscription.error.verification"))
        }
        return .success
    }
}

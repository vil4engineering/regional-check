import Foundation

struct FinishableTransactionUpdate: Sendable {
    let productID: String
    let isVerified: Bool
    let finish: @Sendable () async -> Void
}

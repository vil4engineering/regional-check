import Foundation

enum PurchaseResult: Equatable {
    case success
    case cancelled
    case pending
    case failed(String)
}

import Foundation

enum SubscriptionProductID: String, CaseIterable {
    case monthly = "regioncheck.pro.monthly"
    case yearly = "regioncheck.pro.yearly"

    static var allRawValues: [String] {
        allCases.map(\.rawValue)
    }
}

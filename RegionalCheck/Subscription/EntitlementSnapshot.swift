import Foundation

struct EntitlementSnapshot: Equatable, Codable {
    let productID: String
    let expirationDate: Date?
    let isActive: Bool
    let source: String
    let verifiedAt: Date

    static func inactive(verifiedAt: Date = Date()) -> EntitlementSnapshot {
        EntitlementSnapshot(
            productID: "",
            expirationDate: nil,
            isActive: false,
            source: "none",
            verifiedAt: verifiedAt
        )
    }
}

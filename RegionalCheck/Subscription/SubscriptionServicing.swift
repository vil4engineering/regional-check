import Foundation

protocol SubscriptionServicing: Sendable {
    func loadProducts() async throws -> [SubscriptionProduct]
    func purchase(productID: String) async -> PurchaseResult
    func currentEntitlement() async -> EntitlementSnapshot
    func listenForUpdates() -> AsyncStream<EntitlementSnapshot>
    func restore() async -> EntitlementSnapshot
}

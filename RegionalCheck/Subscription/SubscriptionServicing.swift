import Foundation

protocol SubscriptionServicing: Sendable {
    func loadProducts() async throws -> [SubscriptionProduct]
    func purchase(productID: String) async -> PurchaseResult
    func currentEntitlement() async -> EntitlementVerification
    func listenForUpdates() -> AsyncStream<EntitlementVerification>
    func restore() async -> EntitlementVerification
}

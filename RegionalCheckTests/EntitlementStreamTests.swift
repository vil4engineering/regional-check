import Foundation
@testable import RegionalCheck
import Testing

struct EntitlementStreamTests {
    @Test
    @MainActor
    func entitlementChanges_notifiesOnGrantAndRevoke() async {
        let service = ControllableSubscriptionService()
        let manager = SubscriptionManager(service: service, cache: EntitlementCache())
        let stream = manager.entitlementChanges()
        var notifications = 0
        let consumer = Task { @MainActor in
            for await _ in stream {
                notifications += 1
            }
        }
        await manager.start()
        try? await Task.sleep(for: .milliseconds(50))

        service.push(.active(activeSnapshot))
        await waitForNotificationCount(&notifications, atLeast: 1)

        service.push(.none)
        await waitForNotificationCount(&notifications, atLeast: 2)

        consumer.cancel()
    }
}

@MainActor
private func waitForNotificationCount(_ count: inout Int, atLeast target: Int) async {
    for _ in 0 ..< 50 where count < target {
        try? await Task.sleep(for: .milliseconds(20))
    }
}

private let activeSnapshot = EntitlementSnapshot(
    productID: SubscriptionProductID.yearly.rawValue,
    expirationDate: Date().addingTimeInterval(86400),
    isActive: true,
    source: "storekit",
    verifiedAt: Date()
)

@MainActor
private final class ControllableSubscriptionService: SubscriptionServicing, @unchecked Sendable {
    private var continuation: AsyncStream<EntitlementVerification>.Continuation?

    func loadProducts() async throws -> [SubscriptionProduct] { [] }

    func purchase(productID _: String) async -> PurchaseResult { .cancelled }

    func currentEntitlement() async -> EntitlementVerification { .none }

    func listenForUpdates() -> AsyncStream<EntitlementVerification> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func restore() async -> EntitlementVerification { .none }

    func push(_ verification: EntitlementVerification) {
        continuation?.yield(verification)
    }
}

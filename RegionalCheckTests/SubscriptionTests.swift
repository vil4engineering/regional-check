import Foundation
@testable import RegionalCheck
import Testing

struct SubscriptionTests {
    @Test
    func statusSourceLabel_hidesRawFeedName() {
        let alertFeed = String(localized: "status.source.alertFeed")
        let external = String(localized: "status.source.external")
        #expect(StatusSourceLabel.displayName(for: "Mørk Skogen API (default)") == alertFeed)
        #expect(StatusSourceLabel.displayName(for: "mork skogen") == alertFeed)
        #expect(StatusSourceLabel.displayName(for: "unknown-provider-xyz") == external)
        #expect(StatusSourceLabel.displayName(for: nil) == external)
        #expect(StatusSourceLabel.displayName(for: "") == external)
    }

    @Test
    func entitlementCache_roundTripsActiveSnapshot() {
        let suite = "subscription.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = EntitlementCache(userDefaults: defaults)
        let snapshot = EntitlementSnapshot(
            productID: SubscriptionProductID.yearly.rawValue,
            expirationDate: Date().addingTimeInterval(3600),
            isActive: true,
            source: "storekit",
            verifiedAt: Date(timeIntervalSince1970: 1)
        )
        cache.save(snapshot)
        #expect(cache.load() == snapshot)
        cache.clear()
        #expect(cache.load() == nil)
    }

    @Test
    @MainActor
    func subscriptionManager_usesCachedActiveEntitlement() async {
        let suite = "subscription.manager.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = EntitlementCache(userDefaults: defaults)
        cache.save(
            EntitlementSnapshot(
                productID: SubscriptionProductID.monthly.rawValue,
                expirationDate: Date().addingTimeInterval(86400),
                isActive: true,
                source: "storekit",
                verifiedAt: Date()
            )
        )
        let service = FakeSubscriptionService(
            products: [
                SubscriptionProduct(
                    id: SubscriptionProductID.yearly.rawValue,
                    displayName: "Yearly",
                    displayPrice: "$0.99",
                    periodDescription: "Year"
                ),
            ],
            entitlement: .none
        )
        let manager = SubscriptionManager(service: service, cache: cache)
        #expect(manager.isPro)
        await manager.start()
        #expect(manager.isPro == false)
        #expect(manager.state.products.count == 1)
    }

    @Test
    @MainActor
    func subscriptionManager_purchaseSuccess_unlocksPro() async {
        let suite = "purchase.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeSubscriptionService(
            products: [
                SubscriptionProduct(
                    id: SubscriptionProductID.yearly.rawValue,
                    displayName: "Yearly",
                    displayPrice: "$0.99",
                    periodDescription: "Year"
                ),
            ],
            entitlement: .none,
            purchaseResult: .success,
            entitlementAfterPurchase: EntitlementSnapshot(
                productID: SubscriptionProductID.yearly.rawValue,
                expirationDate: Date().addingTimeInterval(86400),
                isActive: true,
                source: "storekit",
                verifiedAt: Date()
            )
        )
        let manager = SubscriptionManager(service: service, cache: EntitlementCache(userDefaults: defaults))
        let result = await manager.purchase(productID: SubscriptionProductID.yearly.rawValue)
        #expect(result == .success)
        #expect(manager.isPro)
    }

    @Test
    @MainActor
    func subscriptionManager_keepsCacheWhenVerificationFails() async {
        let suite = "subscription.unverified.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = EntitlementCache(userDefaults: defaults)
        cache.save(
            EntitlementSnapshot(
                productID: SubscriptionProductID.monthly.rawValue,
                expirationDate: Date().addingTimeInterval(86400),
                isActive: true,
                source: "storekit",
                verifiedAt: Date()
            )
        )
        let service = FakeSubscriptionService(
            products: [],
            entitlement: .unverified
        )
        let manager = SubscriptionManager(service: service, cache: cache)
        #expect(manager.isPro)
        await manager.start()
        #expect(manager.isPro)
    }

    @Test
    @MainActor
    func subscriptionManager_restoreFailed_keepsCache() async {
        let suite = "subscription.restore.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = EntitlementCache(userDefaults: defaults)
        cache.save(
            EntitlementSnapshot(
                productID: SubscriptionProductID.yearly.rawValue,
                expirationDate: Date().addingTimeInterval(86400),
                isActive: true,
                source: "storekit",
                verifiedAt: Date()
            )
        )
        let service = FakeSubscriptionService(
            products: [],
            entitlement: .unverified,
            restoreEntitlement: .unverified
        )
        let manager = SubscriptionManager(service: service, cache: cache)
        let outcome = await manager.restore()
        #expect(outcome == .failed)
        #expect(manager.isPro)
    }

    @Test
    @MainActor
    func subscriptionManager_restoreEmpty_clearsCache() async {
        let suite = "subscription.restore.empty.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = EntitlementCache(userDefaults: defaults)
        cache.save(
            EntitlementSnapshot(
                productID: SubscriptionProductID.yearly.rawValue,
                expirationDate: Date().addingTimeInterval(86400),
                isActive: true,
                source: "storekit",
                verifiedAt: Date()
            )
        )
        let service = FakeSubscriptionService(
            products: [],
            entitlement: .none,
            restoreEntitlement: .none
        )
        let manager = SubscriptionManager(service: service, cache: cache)
        let outcome = await manager.restore()
        #expect(outcome == .empty)
        #expect(manager.isPro == false)
        #expect(cache.load() == nil)
    }

    @Test
    @MainActor
    func subscriptionManager_purchaseCancelled_doesNotGrantPro() async {
        let service = FakeSubscriptionService(
            products: [],
            entitlement: .none,
            purchaseResult: .cancelled,
            entitlementAfterPurchase: activeTestEntitlement
        )
        let manager = SubscriptionManager(service: service, cache: EntitlementCache())
        _ = await manager.purchase(productID: SubscriptionProductID.yearly.rawValue)
        #expect(manager.isPro == false)
    }

    @Test
    @MainActor
    func subscriptionManager_purchasePending_doesNotGrantPro() async {
        let service = FakeSubscriptionService(
            products: [],
            entitlement: .none,
            purchaseResult: .pending,
            entitlementAfterPurchase: activeTestEntitlement
        )
        let manager = SubscriptionManager(service: service, cache: EntitlementCache())
        _ = await manager.purchase(productID: SubscriptionProductID.yearly.rawValue)
        #expect(manager.isPro == false)
    }

    @Test
    @MainActor
    func subscriptionManager_purchaseFailed_doesNotGrantPro() async {
        let service = FakeSubscriptionService(
            products: [],
            entitlement: .none,
            purchaseResult: .failed("Payment failed"),
            entitlementAfterPurchase: activeTestEntitlement
        )
        let manager = SubscriptionManager(service: service, cache: EntitlementCache())
        _ = await manager.purchase(productID: SubscriptionProductID.yearly.rawValue)
        #expect(manager.isPro == false)
    }

    @Test
    func entitlementCache_expiredSnapshot_isIgnoredByManagerFilter() async {
        let suite = "subscription.expired.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = EntitlementCache(userDefaults: defaults)
        cache.save(
            EntitlementSnapshot(
                productID: SubscriptionProductID.monthly.rawValue,
                expirationDate: Date().addingTimeInterval(-60),
                isActive: true,
                source: "storekit",
                verifiedAt: Date().addingTimeInterval(-3600)
            )
        )
        await MainActor.run {
            let manager = SubscriptionManager(
                service: FakeSubscriptionService(products: [], entitlement: .none),
                cache: EntitlementCache(userDefaults: defaults)
            )
            #expect(manager.isPro == false)
        }
    }
}

private let activeTestEntitlement = EntitlementSnapshot(
    productID: SubscriptionProductID.yearly.rawValue,
    expirationDate: Date().addingTimeInterval(86400),
    isActive: true,
    source: "storekit",
    verifiedAt: Date()
)

private final class FakeSubscriptionService: SubscriptionServicing, @unchecked Sendable {
    let products: [SubscriptionProduct]
    var entitlement: EntitlementVerification
    let purchaseResult: PurchaseResult
    let entitlementAfterPurchase: EntitlementSnapshot?
    var restoreEntitlement: EntitlementVerification?

    init(
        products: [SubscriptionProduct],
        entitlement: EntitlementVerification,
        purchaseResult: PurchaseResult = .cancelled,
        entitlementAfterPurchase: EntitlementSnapshot? = nil,
        restoreEntitlement: EntitlementVerification? = nil
    ) {
        self.products = products
        self.entitlement = entitlement
        self.purchaseResult = purchaseResult
        self.entitlementAfterPurchase = entitlementAfterPurchase
        self.restoreEntitlement = restoreEntitlement
    }

    func loadProducts() async throws -> [SubscriptionProduct] {
        products
    }

    func purchase(productID _: String) async -> PurchaseResult {
        if purchaseResult == .success, let entitlementAfterPurchase {
            entitlement = .active(entitlementAfterPurchase)
        }
        return purchaseResult
    }

    func currentEntitlement() async -> EntitlementVerification {
        entitlement
    }

    func listenForUpdates() -> AsyncStream<EntitlementVerification> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func restore() async -> EntitlementVerification {
        if let restoreEntitlement {
            entitlement = restoreEntitlement
            return restoreEntitlement
        }
        return entitlement
    }
}

import Foundation
@testable import RegionalCheck
import Testing

struct SubscriptionTests {
    @Test
    func premiumAccess_gatesFeatures() {
        let free = PremiumAccess(isPro: false, isLiveActivityEnabled: true)
        #expect(free.allows(.proBadge) == false)
        #expect(free.allows(.extendedDetail) == false)
        #expect(free.allows(.liveActivity) == false)

        let pro = PremiumAccess(isPro: true, isLiveActivityEnabled: true)
        #expect(pro.allows(.proBadge))
        #expect(pro.allows(.extendedDetail))
        #expect(pro.allows(.liveActivity))

        let proDisabledLA = PremiumAccess(isPro: true, isLiveActivityEnabled: false)
        #expect(proDisabledLA.allows(.liveActivity) == false)
        #expect(proDisabledLA.allows(.proBadge))
    }

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
    func liveActivitySession_refcount_endsWithoutCarPlay() {
        let recorder = RecordingLiveActivityController()
        recorder.beginPhoneForegroundSession()
        #expect(recorder.clientCount == 1)
        recorder.endPhoneForegroundSession()
        #expect(recorder.clientCount == 0)
        #expect(recorder.didEndAll)
    }

    @Test
    @MainActor
    func liveActivitySession_refcount_phoneEnds_carPlayKeeps() {
        let recorder = RecordingLiveActivityController()
        recorder.beginPhoneForegroundSession()
        recorder.beginCarPlaySession()
        #expect(recorder.clientCount == 2)
        recorder.endPhoneForegroundSession()
        #expect(recorder.clientCount == 1)
        #expect(recorder.didEndAll == false)
        recorder.endCarPlaySession()
        #expect(recorder.clientCount == 0)
        #expect(recorder.didEndAll)
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

@MainActor
private final class RecordingLiveActivityController: LiveActivityControlling {
    private(set) var clientCount = 0
    private(set) var didEndAll = false
    private var clients: Set<LiveActivitySessionClient> = []

    func beginPhoneForegroundSession() {
        clients.insert(.phoneForeground)
        clientCount = clients.count
    }

    func endPhoneForegroundSession() {
        clients.remove(.phoneForeground)
        clientCount = clients.count
        if clients.isEmpty {
            didEndAll = true
        }
    }

    func beginCarPlaySession() {
        clients.insert(.carPlay)
        clientCount = clients.count
    }

    func endCarPlaySession() {
        clients.remove(.carPlay)
        clientCount = clients.count
        if clients.isEmpty {
            didEndAll = true
        }
    }

    func update(
        phase _: DriveCheckActivityPhase,
        regionTitle _: String,
        checkedAt _: Date?,
        sourceLabel _: String,
        isStale _: Bool
    ) {}

    func endAll() {
        clients.removeAll()
        clientCount = 0
        didEndAll = true
    }
}

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

import Foundation
import Observation

@MainActor
@Observable
final class SubscriptionManager: SubscriptionManaging {
    private(set) var state = SubscriptionState()

    private let service: any SubscriptionServicing
    private let cache: any EntitlementCaching
    private let liveActivityPreferenceKey = "subscription.liveActivity.enabled"
    private var updatesTask: Task<Void, Never>?

    var isPro: Bool {
        state.isPro
    }

    init(
        service: any SubscriptionServicing = StoreKitSubscriptionService(),
        cache: any EntitlementCaching = EntitlementCache()
    ) {
        self.service = service
        self.cache = cache
        if let cached = cache.load() {
            state.entitlement = Self.cachedEntitlementIfValid(cached)
        }
        state.isLiveActivityEnabled = UserDefaults.standard.object(forKey: liveActivityPreferenceKey) as? Bool ?? true
    }

    func start() async {
        applyCachedEntitlement()
        state.loadState = .loading
        let entitlement = await service.currentEntitlement()
        apply(entitlement)
        await refreshProducts()
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in service.listenForUpdates() {
                await MainActor.run {
                    self.apply(snapshot)
                }
            }
        }
    }

    func refreshProducts() async {
        do {
            let products = try await service.loadProducts()
            state.products = products
            if state.loadState != .purchasing {
                state.loadState = .ready
            }
        } catch {
            state.loadState = .error(error.localizedDescription)
        }
    }

    func purchase(productID: String) async -> PurchaseResult {
        state.loadState = .purchasing
        let result = await service.purchase(productID: productID)
        let entitlement = await service.currentEntitlement()
        apply(entitlement)
        state.loadState = .ready
        return result
    }

    func restore() async {
        state.loadState = .loading
        let entitlement = await service.restore()
        apply(entitlement)
        state.loadState = .ready
    }

    func allows(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .proBadge, .extendedDetail:
            isPro
        case .liveActivity:
            isPro && state.isLiveActivityEnabled
        }
    }

    func setLiveActivityEnabled(_ enabled: Bool) {
        state.isLiveActivityEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: liveActivityPreferenceKey)
    }

    private func applyCachedEntitlement() {
        guard let cached = cache.load() else { return }
        state.entitlement = Self.cachedEntitlementIfValid(cached)
    }

    private func apply(_ entitlement: EntitlementSnapshot) {
        state.entitlement = entitlement
        if entitlement.isActive {
            cache.save(entitlement)
        } else {
            cache.clear()
        }
    }

    private static func cachedEntitlementIfValid(_ snapshot: EntitlementSnapshot) -> EntitlementSnapshot? {
        guard snapshot.isActive else { return nil }
        if let expiration = snapshot.expirationDate, expiration <= Date() {
            return nil
        }
        return snapshot
    }
}

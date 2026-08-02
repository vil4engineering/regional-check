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
    private var entitlementChangeContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]

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
        apply(await service.currentEntitlement())
        await refreshProducts()
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await verification in service.listenForUpdates() {
                await MainActor.run {
                    self.apply(verification)
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
        apply(await service.currentEntitlement())
        state.loadState = .ready
        return result
    }

    func restore() async -> RestoreOutcome {
        state.loadState = .loading
        let verification = await service.restore()
        switch verification {
        case .active:
            apply(verification)
            state.loadState = .ready
            return .restored
        case .none:
            apply(verification)
            state.loadState = .ready
            return .empty
        case .unverified:
            state.loadState = .ready
            return .failed
        }
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
        let previous = state.isLiveActivityEnabled
        state.isLiveActivityEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: liveActivityPreferenceKey)
        if previous != enabled {
            notifyEntitlementChange()
        }
    }

    func entitlementChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            entitlementChangeContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.entitlementChangeContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    private func notifyEntitlementChange() {
        for continuation in entitlementChangeContinuations.values {
            continuation.yield()
        }
    }

    private func applyCachedEntitlement() {
        guard let cached = cache.load() else { return }
        state.entitlement = Self.cachedEntitlementIfValid(cached)
    }

    private func apply(_ verification: EntitlementVerification) {
        let wasPro = isPro
        let wasLiveActivityEnabled = state.isLiveActivityEnabled
        switch verification {
        case let .active(snapshot):
            state.entitlement = snapshot
            cache.save(snapshot)
        case .none:
            state.entitlement = nil
            cache.clear()
        case .unverified:
            break
        }
        if isPro != wasPro || state.isLiveActivityEnabled != wasLiveActivityEnabled {
            notifyEntitlementChange()
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

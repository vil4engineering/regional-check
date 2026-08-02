import Foundation
@testable import RegionalCheck
import Testing

struct PaywallViewModelTests {
    @Test
    @MainActor
    func purchaseSuccess_callsDismissAndSync() async {
        var didSync = false
        var didDismiss = false
        let manager = FakeSubscriptionManager(
            purchaseResult: .success,
            entitlementAfterPurchase: EntitlementSnapshot(
                productID: SubscriptionProductID.yearly.rawValue,
                expirationDate: Date().addingTimeInterval(86400),
                isActive: true,
                source: "storekit",
                verifiedAt: Date()
            )
        )
        let viewModel = PaywallViewModel(
            manager: manager,
            syncLiveActivity: { didSync = true },
            onDismiss: { didDismiss = true }
        )
        await viewModel.purchase()
        #expect(didSync)
        #expect(didDismiss)
        #expect(viewModel.isBusy == false)
    }

    @Test
    @MainActor
    func purchasePending_keepsBusy() async {
        let manager = FakeSubscriptionManager(purchaseResult: .pending)
        let viewModel = PaywallViewModel(manager: manager)
        await viewModel.purchase()
        #expect(viewModel.isBusy)
        #expect(viewModel.statusMessage == String(localized: "subscription.purchase.pending"))
    }

    @Test
    @MainActor
    func restoreFailed_showsDistinctMessage() async {
        let manager = FakeSubscriptionManager(restoreOutcome: .failed)
        let viewModel = PaywallViewModel(manager: manager)
        await viewModel.restore()
        #expect(viewModel.statusMessage == String(localized: "subscription.restore.failed"))
    }

    @Test
    @MainActor
    func loadErrorMessage_surfacesStoreError() {
        let manager = FakeSubscriptionManager(loadState: .error("Store unavailable"))
        let viewModel = PaywallViewModel(manager: manager)
        #expect(viewModel.loadErrorMessage == "Store unavailable")
    }
}

@MainActor
private final class FakeSubscriptionManager: SubscriptionManaging {
    var state: SubscriptionState
    var isPro: Bool { state.isPro }
    private let purchaseResult: PurchaseResult
    private let restoreOutcome: RestoreOutcome

    init(
        purchaseResult: PurchaseResult = .cancelled,
        entitlementAfterPurchase: EntitlementSnapshot? = nil,
        restoreOutcome: RestoreOutcome = .empty,
        loadState: SubscriptionLoadState = .ready
    ) {
        self.purchaseResult = purchaseResult
        self.restoreOutcome = restoreOutcome
        state = SubscriptionState(loadState: loadState)
        if let entitlementAfterPurchase {
            state.entitlement = entitlementAfterPurchase
        }
    }

    func start() async {}

    func refreshProducts() async {}

    func purchase(productID _: String) async -> PurchaseResult {
        purchaseResult
    }

    func restore() async -> RestoreOutcome {
        restoreOutcome
    }

    func allows(_: PremiumFeature) -> Bool {
        isPro
    }

    func setLiveActivityEnabled(_ enabled: Bool) {
        state.isLiveActivityEnabled = enabled
    }

    func entitlementChanges() -> AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }
}

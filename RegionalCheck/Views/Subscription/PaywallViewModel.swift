import Foundation
import Observation

@MainActor
@Observable
final class PaywallViewModel {
    enum PlansContent: Equatable {
        case loading
        case empty
        case ready([SubscriptionProduct])
    }

    private let manager: any SubscriptionManaging
    private let syncLiveActivity: () -> Void
    private let onDismiss: () -> Void

    var selectedProductID: String = SubscriptionProductID.yearly.rawValue
    var statusMessage: String?
    var isBusy = false
    private(set) var isLoadingProducts = false

    var products: [SubscriptionProduct] {
        manager.state.products
    }

    var selectedProduct: SubscriptionProduct? {
        products.first(where: { $0.id == selectedProductID }) ?? products.first
    }

    var plansContent: PlansContent {
        if isLoadingProducts, products.isEmpty {
            .loading
        } else if products.isEmpty {
            .empty
        } else {
            .ready(products)
        }
    }

    var subscribeTitle: String {
        if let product = selectedProduct {
            String(
                localized: "subscription.paywall.subscribePrice \(product.displayPrice)"
            )
        } else {
            String(localized: "subscription.paywall.subscribe")
        }
    }

    var isPro: Bool {
        manager.isPro
    }

    var loadState: SubscriptionLoadState {
        manager.state.loadState
    }

    var loadErrorMessage: String? {
        if case let .error(message) = loadState {
            return message
        }
        return nil
    }

    init(
        manager: any SubscriptionManaging,
        syncLiveActivity: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void = {}
    ) {
        self.manager = manager
        self.syncLiveActivity = syncLiveActivity
        self.onDismiss = onDismiss
        selectPreferredProduct()
    }

    func onAppear() async {
        await reloadProducts()
    }

    func reloadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        await manager.refreshProducts()
        selectPreferredProduct()
    }

    func purchase() async {
        guard let productID = selectedProduct?.id else { return }
        guard !isBusy else { return }
        isBusy = true
        let result = await manager.purchase(productID: productID)
        switch result {
        case .success:
            syncLiveActivity()
            isBusy = false
            onDismiss()
        case .cancelled:
            statusMessage = nil
            isBusy = false
        case .pending:
            statusMessage = String(localized: "subscription.purchase.pending")
        case let .failed(message):
            statusMessage = message
            isBusy = false
        }
    }

    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        let outcome = await manager.restore()
        switch outcome {
        case .restored:
            statusMessage = String(localized: "subscription.restore.success")
            syncLiveActivity()
        case .empty:
            statusMessage = String(localized: "subscription.restore.empty")
        case .failed:
            statusMessage = String(localized: "subscription.restore.failed")
        }
    }

    private func selectPreferredProduct() {
        if let yearly = products.first(where: { $0.id == SubscriptionProductID.yearly.rawValue }) {
            selectedProductID = yearly.id
        } else if let first = products.first {
            selectedProductID = first.id
        }
    }
}

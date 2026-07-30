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

    private let manager: SubscriptionManager

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

    init(manager: SubscriptionManager) {
        self.manager = manager
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
        isBusy = true
        defer { isBusy = false }
        let result = await manager.purchase(productID: productID)
        switch result {
        case .success:
            statusMessage = String(localized: "subscription.purchase.success")
            AppDependencies.syncLiveActivityContent()
        case .cancelled:
            statusMessage = nil
        case .pending:
            statusMessage = String(localized: "subscription.purchase.pending")
        case let .failed(message):
            statusMessage = message
        }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        await manager.restore()
        statusMessage = manager.isPro
            ? String(localized: "subscription.restore.success")
            : String(localized: "subscription.restore.empty")
        AppDependencies.syncLiveActivityContent()
    }

    private func selectPreferredProduct() {
        if let yearly = products.first(where: { $0.id == SubscriptionProductID.yearly.rawValue }) {
            selectedProductID = yearly.id
        } else if let first = products.first {
            selectedProductID = first.id
        }
    }
}

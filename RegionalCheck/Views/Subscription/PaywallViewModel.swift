import Foundation
import Observation

@MainActor
@Observable
final class PaywallViewModel {
    private let manager: SubscriptionManager

    var selectedProductID: String = SubscriptionProductID.yearly.rawValue
    var statusMessage: String?
    var isBusy = false

    var products: [SubscriptionProduct] {
        manager.state.products
    }

    var isPro: Bool {
        manager.isPro
    }

    var loadState: SubscriptionLoadState {
        manager.state.loadState
    }

    init(manager: SubscriptionManager) {
        self.manager = manager
        if let yearly = manager.state.products.first(where: { $0.id == SubscriptionProductID.yearly.rawValue }) {
            selectedProductID = yearly.id
        } else if let first = manager.state.products.first {
            selectedProductID = first.id
        }
    }

    func onAppear() async {
        if manager.state.products.isEmpty {
            await manager.refreshProducts()
        }
        if let yearly = manager.state.products.first(where: { $0.id == SubscriptionProductID.yearly.rawValue }) {
            selectedProductID = yearly.id
        }
    }

    func purchase() async {
        isBusy = true
        defer { isBusy = false }
        let result = await manager.purchase(productID: selectedProductID)
        switch result {
        case .success:
            statusMessage = String(localized: "subscription.purchase.success")
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
    }
}

import Foundation
import StoreKit

struct StoreKitSubscriptionService: SubscriptionServicing {
    func loadProducts() async throws -> [SubscriptionProduct] {
        let storeProducts = try await Product.products(for: SubscriptionProductID.allRawValues)
        return storeProducts
            .sorted { lhs, rhs in
                sortRank(lhs.id) < sortRank(rhs.id)
            }
            .map(mapProduct)
    }

    func purchase(productID: String) async -> PurchaseResult {
        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                return .failed(String(localized: "subscription.error.unavailable"))
            }
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    await transaction.finish()
                    return .success
                case .unverified:
                    return .failed(String(localized: "subscription.error.verification"))
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(String(localized: "subscription.error.unavailable"))
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func currentEntitlement() async -> EntitlementSnapshot {
        await mapEntitlements()
    }

    func restore() async -> EntitlementSnapshot {
        try? await AppStore.sync()
        return await mapEntitlements()
    }

    func listenForUpdates() -> AsyncStream<EntitlementSnapshot> {
        AsyncStream { continuation in
            let task = Task {
                for await _ in Transaction.updates {
                    let snapshot = await mapEntitlements()
                    continuation.yield(snapshot)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func mapEntitlements() async -> EntitlementSnapshot {
        var best: EntitlementSnapshot?
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            guard SubscriptionProductID(rawValue: transaction.productID) != nil else { continue }
            let expiration = transaction.expirationDate
            let active: Bool = if let expiration {
                expiration > Date()
            } else {
                transaction.revocationDate == nil
            }
            let candidate = EntitlementSnapshot(
                productID: transaction.productID,
                expirationDate: expiration,
                isActive: active && transaction.revocationDate == nil,
                source: "storekit",
                verifiedAt: Date()
            )
            if candidate.isActive {
                if let current = best {
                    let currentExp = current.expirationDate ?? .distantPast
                    let nextExp = candidate.expirationDate ?? .distantPast
                    if nextExp >= currentExp {
                        best = candidate
                    }
                } else {
                    best = candidate
                }
            }
        }
        return best ?? .inactive()
    }

    private func mapProduct(_ product: Product) -> SubscriptionProduct {
        let period: String = if let subscription = product.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .year:
                String(localized: "subscription.period.year")
            case .month:
                String(localized: "subscription.period.month")
            case .week:
                String(localized: "subscription.period.week")
            case .day:
                String(localized: "subscription.period.day")
            @unknown default:
                product.description
            }
        } else {
            product.description
        }
        return SubscriptionProduct(
            id: product.id,
            displayName: product.displayName,
            displayPrice: product.displayPrice,
            periodDescription: period
        )
    }

    private func sortRank(_ id: String) -> Int {
        switch SubscriptionProductID(rawValue: id) {
        case .yearly:
            0
        case .monthly:
            1
        case nil:
            2
        }
    }
}

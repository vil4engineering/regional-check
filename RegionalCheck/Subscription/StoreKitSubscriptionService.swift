import Foundation
import StoreKit

struct StoreKitSubscriptionService: SubscriptionServicing {
    private let updates: @Sendable () -> AsyncStream<FinishableTransactionUpdate>
    private let entitlements: @Sendable () async -> EntitlementSnapshot

    init(
        updates: @escaping @Sendable () -> AsyncStream<FinishableTransactionUpdate> = {
            StoreKitSubscriptionService.liveUpdates()
        },
        entitlements: (@Sendable () async -> EntitlementSnapshot)? = nil
    ) {
        self.updates = updates
        self.entitlements = entitlements ?? {
            await StoreKitSubscriptionService.mapEntitlements()
        }
    }

    func loadProducts() async throws -> [SubscriptionProduct] {
        let storeProducts = try await Product.products(for: SubscriptionProductID.allRawValues)
        let mapped = storeProducts
            .sorted { lhs, rhs in
                sortRank(lhs.id) < sortRank(rhs.id)
            }
            .map(mapProduct)
        if mapped.isEmpty {
            return Self.debugCatalogProducts
        }
        return mapped
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
                    return await StoreKitPurchaseVerification.handleSuccess(
                        isVerified: true,
                        finish: { await transaction.finish() }
                    )
                case let .unverified(transaction, _):
                    return await StoreKitPurchaseVerification.handleSuccess(
                        isVerified: false,
                        finish: { await transaction.finish() }
                    )
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
        await entitlements()
    }

    func restore() async -> EntitlementSnapshot {
        try? await AppStore.sync()
        return await entitlements()
    }

    func listenForUpdates() -> AsyncStream<EntitlementSnapshot> {
        AsyncStream { continuation in
            let task = Task {
                for await update in updates() {
                    await update.finish()
                    let snapshot = await entitlements()
                    continuation.yield(snapshot)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static func liveUpdates() -> AsyncStream<FinishableTransactionUpdate> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    switch result {
                    case let .verified(transaction):
                        continuation.yield(
                            FinishableTransactionUpdate(
                                productID: transaction.productID,
                                isVerified: true,
                                finish: { await transaction.finish() }
                            )
                        )
                    case let .unverified(transaction, _):
                        continuation.yield(
                            FinishableTransactionUpdate(
                                productID: transaction.productID,
                                isVerified: false,
                                finish: { await transaction.finish() }
                            )
                        )
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static func mapEntitlements() async -> EntitlementSnapshot {
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

    private static var debugCatalogProducts: [SubscriptionProduct] {
        #if DEBUG
            [
                SubscriptionProduct(
                    id: SubscriptionProductID.yearly.rawValue,
                    displayName: String(localized: "Pro Yearly"),
                    displayPrice: "$0.99",
                    periodDescription: String(localized: "subscription.period.year")
                ),
                SubscriptionProduct(
                    id: SubscriptionProductID.monthly.rawValue,
                    displayName: String(localized: "Pro Monthly"),
                    displayPrice: "$0.29",
                    periodDescription: String(localized: "subscription.period.month")
                ),
            ]
        #else
            []
        #endif
    }
}

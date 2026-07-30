import Foundation
@testable import RegionalCheck
import StoreKitTest
import Testing

struct StoreKitConfigurationFlowTests {
    @Test
    @MainActor
    func storeKitConfig_loadsProducts_andPurchaseUnlocksPro() async throws {
        let storeKitURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("RegionalCheck/Resources/Products.storekit")
        #expect(FileManager.default.fileExists(atPath: storeKitURL.path))

        let session = try SKTestSession(contentsOf: storeKitURL)
        session.disableDialogs = true
        session.clearTransactions()

        let service = StoreKitSubscriptionService()
        let products = try await service.loadProducts()
        let ids = Set(products.map(\.id))
        #expect(ids.contains(SubscriptionProductID.yearly.rawValue))
        #expect(ids.contains(SubscriptionProductID.monthly.rawValue))
        #expect(products.allSatisfy { !$0.displayPrice.isEmpty })

        let purchase = await service.purchase(productID: SubscriptionProductID.yearly.rawValue)
        #expect(purchase == .success)

        let entitlement = await service.currentEntitlement()
        #expect(entitlement.isActive)
        #expect(entitlement.productID == SubscriptionProductID.yearly.rawValue)

        let suite = "storekit.flow.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("Missing UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let manager = SubscriptionManager(
            service: service,
            cache: EntitlementCache(userDefaults: defaults)
        )
        await manager.start()
        #expect(manager.isPro)
        #expect(manager.allows(.liveActivity))
        #expect(manager.allows(.proBadge))
        #expect(manager.allows(.extendedDetail))

        session.clearTransactions()
        _ = session
    }
}

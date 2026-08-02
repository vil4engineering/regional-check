import Foundation
@testable import RegionalCheck
import Testing

struct StoreKitTransactionFinishTests {
    @Test
    func listenForUpdates_finishesVerifiedTransaction() async {
        let recorder = FinishRecorder()
        let service = StoreKitSubscriptionService(
            updates: {
                AsyncStream { continuation in
                    continuation.yield(
                        FinishableTransactionUpdate(
                            productID: SubscriptionProductID.yearly.rawValue,
                            isVerified: true,
                            finish: { await recorder.markFinished() }
                        )
                    )
                    continuation.finish()
                }
            },
            entitlements: { .inactive() }
        )

        var yielded = 0
        for await _ in service.listenForUpdates() {
            yielded += 1
        }

        #expect(yielded == 1)
        #expect(await recorder.count == 1)
    }

    @Test
    func listenForUpdates_finishesUnverifiedTransaction() async {
        let recorder = FinishRecorder()
        let service = StoreKitSubscriptionService(
            updates: {
                AsyncStream { continuation in
                    continuation.yield(
                        FinishableTransactionUpdate(
                            productID: SubscriptionProductID.monthly.rawValue,
                            isVerified: false,
                            finish: { await recorder.markFinished() }
                        )
                    )
                    continuation.finish()
                }
            },
            entitlements: { .inactive() }
        )

        for await _ in service.listenForUpdates() {}

        #expect(await recorder.count == 1)
    }

    @Test
    func purchaseVerification_finishesUnverifiedAndDoesNotSucceed() async {
        let recorder = FinishRecorder()
        let result = await StoreKitPurchaseVerification.handleSuccess(
            isVerified: false,
            finish: { await recorder.markFinished() }
        )
        #expect(result == .failed(String(localized: "subscription.error.verification")))
        #expect(await recorder.count == 1)
    }

    @Test
    func purchaseVerification_finishesVerifiedAndSucceeds() async {
        let recorder = FinishRecorder()
        let result = await StoreKitPurchaseVerification.handleSuccess(
            isVerified: true,
            finish: { await recorder.markFinished() }
        )
        #expect(result == .success)
        #expect(await recorder.count == 1)
    }
}

private actor FinishRecorder {
    private(set) var count = 0

    func markFinished() {
        count += 1
    }
}

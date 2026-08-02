import Foundation
@testable import RegionalCheck
import Testing

struct DataFreshnessTests {
    @Test
    func marksStaleAfterTwoIntervals() {
        let checkedAt = Date(timeIntervalSince1970: 0)
        #expect(
            DataFreshness.isStale(
                checkedAt: checkedAt,
                now: Date(timeIntervalSince1970: 121),
                refreshIntervalSeconds: 60
            )
        )
        #expect(
            DataFreshness.isStale(
                checkedAt: checkedAt,
                now: Date(timeIntervalSince1970: 120),
                refreshIntervalSeconds: 60
            ) == false
        )
    }
}

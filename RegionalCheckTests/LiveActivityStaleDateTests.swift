import Foundation
@testable import RegionalCheck
import Testing

struct LiveActivityStaleDateTests {
    @Test
    func usesCheckedAtPlusDoubleRefreshInterval() {
        let checkedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let stale = LiveActivityStaleDate.make(
            checkedAt: checkedAt,
            now: Date(timeIntervalSince1970: 1_700_000_500),
            refreshInterval: 300
        )
        #expect(stale == checkedAt.addingTimeInterval(600))
    }

    @Test
    func fallsBackToNowWhenCheckedAtMissing() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let stale = LiveActivityStaleDate.make(
            checkedAt: nil,
            now: now,
            refreshInterval: 60
        )
        #expect(stale == now.addingTimeInterval(120))
    }
}

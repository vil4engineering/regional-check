import Foundation

enum LiveActivityStaleDate {
    static func make(
        checkedAt: Date?,
        now: Date = Date(),
        refreshInterval: TimeInterval
    ) -> Date {
        let base = checkedAt ?? now
        return base.addingTimeInterval(refreshInterval * 2)
    }
}

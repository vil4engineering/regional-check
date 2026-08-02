import Foundation

enum DataFreshness {
    static func isStale(checkedAt: Date, now: Date, refreshIntervalSeconds: TimeInterval) -> Bool {
        guard refreshIntervalSeconds > 0 else { return false }
        return now.timeIntervalSince(checkedAt) > refreshIntervalSeconds * 2
    }
}

import Foundation

struct AlertsSnapshot: Equatable, Sendable {
    let source: String
    let serverCachedAt: Date?
    let fetchedAt: Date
    let statuses: [AlertRegion: AlertStatus]

    func status(for region: AlertRegion) -> AlertStatus? {
        statuses[region]
    }

    var checkedAt: Date {
        serverCachedAt ?? fetchedAt
    }
}

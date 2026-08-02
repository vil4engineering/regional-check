import Foundation

public struct AlertsSnapshot: Equatable, Sendable, Codable {
    public let source: String
    public let serverCachedAt: Date?
    public let fetchedAt: Date
    public let statuses: [AlertRegion: AlertStatus]

    public init(
        source: String,
        serverCachedAt: Date?,
        fetchedAt: Date,
        statuses: [AlertRegion: AlertStatus]
    ) {
        self.source = source
        self.serverCachedAt = serverCachedAt
        self.fetchedAt = fetchedAt
        self.statuses = statuses
    }

    public func status(for region: AlertRegion) -> AlertStatus? {
        statuses[region]
    }

    public var checkedAt: Date {
        serverCachedAt ?? fetchedAt
    }
}

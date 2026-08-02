import Foundation

public struct WidgetStatusPresentation: Equatable, Sendable {
    public let phase: DriveCheckActivityPhase
    public let regionTitle: String
    public let checkedAt: Date?
    public let isStale: Bool
    public let sourceLabel: String?

    public init(
        phase: DriveCheckActivityPhase,
        regionTitle: String,
        checkedAt: Date?,
        isStale: Bool,
        sourceLabel: String? = nil
    ) {
        self.phase = phase
        self.regionTitle = regionTitle
        self.checkedAt = checkedAt
        self.isStale = isStale
        self.sourceLabel = sourceLabel
    }
}

public enum WidgetTimelineBuilder {
    public static let defaultReloadInterval: TimeInterval = 60
    public static let defaultStaleThreshold: TimeInterval = 120

    public static func presentation(
        store: SharedStore,
        region: AlertRegion? = nil,
        now: Date = Date(),
        staleThreshold: TimeInterval = defaultStaleThreshold
    ) -> WidgetStatusPresentation {
        let selected = region ?? store.loadRegion() ?? .kyivCity
        guard let snapshot = store.loadSnapshot() else {
            return WidgetStatusPresentation(
                phase: .idle,
                regionTitle: selected.title,
                checkedAt: nil,
                isStale: false
            )
        }
        let checkedAt = snapshot.checkedAt
        let isStale = now.timeIntervalSince(checkedAt) > staleThreshold
        let phase: DriveCheckActivityPhase = switch snapshot.status(for: selected) {
        case .alarm: .alarm
        case .quiet: .quiet
        case nil: .error
        }
        let sourceLabel = store.loadIsPro() ? snapshot.source : nil
        return WidgetStatusPresentation(
            phase: phase,
            regionTitle: selected.title,
            checkedAt: checkedAt,
            isStale: isStale,
            sourceLabel: sourceLabel
        )
    }

    public static func reloadDate(
        from now: Date = Date(),
        interval: TimeInterval = defaultReloadInterval
    ) -> Date {
        now.addingTimeInterval(interval)
    }
}

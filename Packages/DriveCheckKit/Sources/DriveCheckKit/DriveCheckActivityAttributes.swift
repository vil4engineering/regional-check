import ActivityKit
import Foundation

public struct DriveCheckActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var phase: DriveCheckActivityPhase
        public var regionTitle: String
        public var checkedAt: Date?
        public var sourceLabel: String
        public var isStale: Bool

        public init(
            phase: DriveCheckActivityPhase,
            regionTitle: String,
            checkedAt: Date?,
            sourceLabel: String,
            isStale: Bool = false
        ) {
            self.phase = phase
            self.regionTitle = regionTitle
            self.checkedAt = checkedAt
            self.sourceLabel = sourceLabel
            self.isStale = isStale
        }
    }

    public init() {}
}

public enum DriveCheckActivityPhase: String, Codable, Hashable, Sendable {
    case idle
    case quiet
    case alarm
    case error

    public var symbolName: String {
        switch self {
        case .alarm:
            "exclamationmark.circle.fill"
        case .quiet:
            "checkmark.circle.fill"
        case .idle:
            "arrow.triangle.2.circlepath"
        case .error:
            "questionmark.circle.fill"
        }
    }

    public var titleKey: String {
        switch self {
        case .alarm:
            "Alert Active"
        case .quiet:
            "All Clear"
        case .idle:
            "Checking…"
        case .error:
            "Unavailable"
        }
    }
}

import Foundation
import Observation
import os

enum StatusState: Equatable {
    enum Phase: Equatable {
        case idle
        case quiet
        case alarm
        case error
    }

    case idle
    case quiet(lastCheckedAt: Date)
    case alarm(lastCheckedAt: Date)
    case error

    var phase: Phase {
        switch self {
        case .idle:
            .idle
        case .quiet:
            .quiet
        case .alarm:
            .alarm
        case .error:
            .error
        }
    }

    var title: String {
        switch self {
        case .alarm:
            String(localized: "Alert Active")
        case .quiet:
            String(localized: "All Clear")
        case .idle:
            String(localized: "Checking…")
        case .error:
            String(localized: "Unavailable")
        }
    }

    var symbolName: String {
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

    var explanation: String {
        switch self {
        case .quiet:
            String(localized: "status.explanation.quiet")
        case .alarm:
            String(localized: "status.explanation.loud")
        case .idle:
            String(localized: "status.explanation.updating")
        case .error:
            String(localized: "status.explanation.unknown")
        }
    }

    var detailText: String? {
        switch self {
        case let .alarm(lastCheckedAt), let .quiet(lastCheckedAt):
            String(format: String(localized: "Updated: %@"), lastCheckedAt.formatted(date: .omitted, time: .shortened))
        case .error:
            String(localized: "Tap Refresh to try again")
        case .idle:
            nil
        }
    }

    var checkedAt: Date? {
        switch self {
        case let .alarm(lastCheckedAt), let .quiet(lastCheckedAt):
            lastCheckedAt
        case .idle, .error:
            nil
        }
    }
}

@MainActor
@Observable
final class StatusController {
    private static let log = Logger(subsystem: "vil4max.RegionalCheck", category: "Status")

    private(set) var state: StatusState = .error
    private(set) var regionTitle: String
    private(set) var isLoading = false
    private(set) var checkedAtLabel: String?

    private var region: AlertRegion
    private let provider: any StatusProviding

    init(
        region: AlertRegion,
        provider: any StatusProviding
    ) {
        self.region = region
        self.provider = provider
        regionTitle = region.title
    }

    func setRegion(_ region: AlertRegion) {
        self.region = region
        regionTitle = region.title
    }

    func applyScreenshotFixture(_ phase: String) {
        let checkedAt = Date(timeIntervalSince1970: 1_720_000_000)
        switch phase {
        case "allClear":
            setRegion(.kyivCity)
            state = .quiet(lastCheckedAt: checkedAt)
        case "alertActive":
            setRegion(AlertRegion(kind: .oblast(name: "Харківська область")))
            state = .alarm(lastCheckedAt: checkedAt)
        case "checking":
            setRegion(AlertRegion(kind: .oblast(name: "Харківська область")))
            state = .idle
        case "unavailable":
            setRegion(.kyivCity)
            state = .error
        default:
            break
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let snapshot = try await provider.fetchStatus(region: region)
            let label = snapshot.checkedAt.formatted(date: .omitted, time: .shortened)
            switch snapshot.status {
            case .alarm:
                state = .alarm(lastCheckedAt: snapshot.checkedAt)
            case .quiet:
                state = .quiet(lastCheckedAt: snapshot.checkedAt)
            }
            checkedAtLabel = label
        } catch {
            Self.log.error("Fetch status failed: \(String(describing: error), privacy: .public)")
            state = .error
            checkedAtLabel = nil
        }
    }
}

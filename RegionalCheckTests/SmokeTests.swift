import Foundation
@testable import RegionalCheck
import Testing

struct SmokeTests {
    @Test
    func allStates_showExpectedTitlesAndSymbols() {
        let checkedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let idle = StatusState.idle
        let quiet = StatusState.quiet(lastCheckedAt: checkedAt)
        let alarm = StatusState.alarm(lastCheckedAt: checkedAt)
        let error = StatusState.error
        let regionUnavailable = StatusState.regionUnavailable

        #expect(idle.title == "Checking…")
        #expect(quiet.title == "All Clear")
        #expect(alarm.title == "Alert Active")
        #expect(error.title == "Unavailable")
        #expect(regionUnavailable.title == "Region Unavailable")

        #expect(idle.phase == .idle)
        #expect(quiet.phase == .quiet)
        #expect(alarm.phase == .alarm)
        #expect(error.phase == .error)
        #expect(regionUnavailable.phase == .regionUnavailable)
        #expect(StatusState.quiet(lastCheckedAt: checkedAt).phase
            == StatusState.quiet(lastCheckedAt: Date(timeIntervalSince1970: 2)).phase)

        #expect(idle.symbolName == "arrow.triangle.2.circlepath")
        #expect(quiet.symbolName == "checkmark.circle.fill")
        #expect(alarm.symbolName == "exclamationmark.circle.fill")
        #expect(error.symbolName == "questionmark.circle.fill")

        #expect(idle.explanation == String(localized: "status.explanation.updating"))
        #expect(quiet.explanation == String(localized: "status.explanation.quiet"))
        #expect(alarm.explanation == String(localized: "status.explanation.loud"))
        #expect(error.explanation == String(localized: "status.explanation.unknown"))

        #expect(idle.detailText == nil)
        #expect(error.detailText == "Tap Refresh to try again")
        #expect(quiet.detailText?.hasPrefix("Updated:") == true)
        #expect(alarm.detailText?.hasPrefix("Updated:") == true)
        #expect(quiet.checkedAt == checkedAt)
        #expect(alarm.checkedAt == checkedAt)
        #expect(idle.checkedAt == nil)
        #expect(error.checkedAt == nil)
        #expect(quiet.detailText == StatusState.quiet(lastCheckedAt: checkedAt).detailText)
        #expect(alarm.detailText == String(
            format: String(localized: "Updated: %@"),
            checkedAt.formatted(date: .omitted, time: .shortened)
        ))
    }

    @Test
    func onboardingPurpose_usesExpectedCTAKeys() {
        #expect(OnboardingPurpose.firstLaunch.ctaTitleKey == "Get Started")
        #expect(OnboardingPurpose.about.ctaTitleKey == "Got It")
    }

    @Test
    @MainActor
    func controller_appliesScreenshotFixtures() {
        let provider = MockStatusProvider(
            snapshot: AlertsSnapshot(
                source: "test",
                serverCachedAt: Date(),
                fetchedAt: Date(),
                statuses: [.kyivCity: .quiet]
            )
        )
        let controller = StatusController(region: .kyivCity, provider: provider)

        controller.applyScreenshotFixture("allClear")
        #expect(controller.state.title == "All Clear")
        #expect(controller.regionTitle == String(localized: "Kyiv"))

        controller.applyScreenshotFixture("alertActive")
        #expect(controller.state.title == "Alert Active")

        controller.applyScreenshotFixture("checking")
        #expect(controller.state == .idle)

        controller.applyScreenshotFixture("unavailable")
        #expect(controller.state == .error)
    }

    @Test
    func regionTitles_matchBusinessRules() {
        #expect(AlertRegion.kyivCity.title == String(localized: "Kyiv"))
        #expect(AlertRegion.lviv.title == String(localized: "Львівська область"))
    }

    @Test
    @MainActor
    func controller_startsIdle_thenShowsQuiet() async {
        let checkedAt = Date(timeIntervalSince1970: 1)
        let provider = MockStatusProvider(
            snapshot: AlertsSnapshot(
                source: "test",
                serverCachedAt: checkedAt,
                fetchedAt: checkedAt,
                statuses: [.kyivCity: .quiet]
            )
        )
        let controller = StatusController(region: .kyivCity, provider: provider)

        #expect(controller.state == .idle)
        #expect(controller.regionTitle == String(localized: "Kyiv"))
        #expect(controller.state.explanation == String(localized: "status.explanation.updating"))

        await controller.refresh()

        guard case let .quiet(lastCheckedAt) = controller.state else {
            Issue.record("Expected quiet state, got \(controller.state)")
            return
        }
        #expect(lastCheckedAt == checkedAt)
        #expect(controller.state.title == "All Clear")
        #expect(controller.state.explanation == String(localized: "status.explanation.quiet"))
        #expect(controller.state.detailText?.hasPrefix("Updated:") == true)
    }

    @Test
    @MainActor
    func controller_showsAlarmFromProvider() async {
        let checkedAt = Date(timeIntervalSince1970: 1)
        let provider = MockStatusProvider(
            snapshot: AlertsSnapshot(
                source: "test",
                serverCachedAt: checkedAt,
                fetchedAt: checkedAt,
                statuses: [.kyivCity: .alarm]
            )
        )
        let controller = StatusController(region: .kyivCity, provider: provider)

        await controller.refresh()

        guard case let .alarm(lastCheckedAt) = controller.state else {
            Issue.record("Expected alarm state, got \(controller.state)")
            return
        }
        #expect(lastCheckedAt == checkedAt)
        #expect(controller.state.title == "Alert Active")
        #expect(controller.state.explanation == String(localized: "status.explanation.loud"))
    }

    @Test
    @MainActor
    func controller_showsUnknownOnFailure() async {
        struct TestError: Error {}
        let provider = MockStatusProvider(error: TestError())
        let controller = StatusController(region: .kyivCity, provider: provider)

        await controller.refresh()

        #expect(controller.state == .error)
        #expect(controller.state.title == "Unavailable")
        #expect(controller.state.detailText == "Tap Refresh to try again")
    }

    @Test
    @MainActor
    func statusController_periodicRefreshInterval_isFiveMinutes() {
        #expect(StatusController.periodicRefreshInterval == .seconds(300))
    }

    @Test
    @MainActor
    func controller_updatesRegionTitle() {
        let provider = MockStatusProvider(
            snapshot: AlertsSnapshot(
                source: "test",
                serverCachedAt: Date(),
                fetchedAt: Date(),
                statuses: [.kyivCity: .quiet, .kyivOblast: .quiet]
            )
        )
        let controller = StatusController(region: .kyivCity, provider: provider)
        controller.setRegion(.kyivOblast)
        #expect(controller.regionTitle == String(localized: "Київська область"))
    }

    @Test
    func provider_parsesKyivAlarmFromJSON() async throws {
        let provider = try makeProvider(json: kyivJSON(alertnow: true), now: Date(timeIntervalSince1970: 123))
        let snapshot = try await provider.fetchAlerts()
        #expect(snapshot.status(for: .kyivCity) == .alarm)
        #expect(snapshot.source == "test")
        #expect(snapshot.fetchedAt == Date(timeIntervalSince1970: 123))
    }

    @Test
    func provider_parsesKyivQuietFromJSON() async throws {
        let provider = try makeProvider(json: kyivJSON(alertnow: false))
        let snapshot = try await provider.fetchAlerts()
        #expect(snapshot.status(for: .kyivCity) == .quiet)
    }

    @Test
    func provider_parsesOblastAlarmFromJSON() async throws {
        let json = """
        {
          "source": "test",
          "cachedat": "2026-01-01 00:00:00",
          "states": {
            "Львівська область": { "alertnow": true, "changed": "2026-01-01 00:00:00" }
          }
        }
        """
        let provider = try makeProvider(json: json)
        let snapshot = try await provider.fetchAlerts()
        #expect(snapshot.status(for: .lviv) == .alarm)
    }

    @Test
    func provider_omitsMissingRegionFromSnapshot() async throws {
        let provider = try makeProvider(json: kyivJSON(alertnow: true))
        let snapshot = try await provider.fetchAlerts()
        #expect(snapshot.status(for: .odesa) == nil)
        #expect(snapshot.status(for: .kyivCity) == .alarm)
    }

    @Test
    func provider_throwsOnHTTPError() async throws {
        let url = try #require(URL(string: "https://ubilling.net.ua/aerialalerts/"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        ))
        let http = MockHTTPClient(data: Data("{}".utf8), response: response)
        let provider = UbillingProvider(httpClient: http)

        do {
            _ = try await provider.fetchAlerts()
            Issue.record("Expected HTTP error")
        } catch let error as UbillingError {
            guard case let .unexpectedResponse(statusCode, _, _) = error else {
                Issue.record("Expected unexpectedResponse, got \(error)")
                return
            }
            #expect(statusCode == 500)
        } catch {
            Issue.record("Expected UbillingError, got \(error)")
        }
    }

    @Test
    func regionStore_savesAndLoadsRegions() throws {
        let suite = "SmokeTests.RegionStore.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RegionStore(userDefaults: defaults)

        store.save(.kyivCity)
        #expect(store.load() == .kyivCity)

        store.save(.kharkiv)
        #expect(store.load() == .kharkiv)
    }
}

private func kyivJSON(alertnow: Bool) -> String {
    """
    {
      "source": "test",
      "cachedat": "2026-01-01 00:00:00",
      "states": {
        "м. Київ": { "alertnow": \(alertnow), "changed": "2026-01-01 00:00:00" }
      }
    }
    """
}

private func makeProvider(json: String, now: Date = Date()) throws -> UbillingProvider {
    let data = Data(json.utf8)
    let response = HTTPURLResponse(
        url: URL(string: "https://ubilling.net.ua/aerialalerts/")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    let http = MockHTTPClient(data: data, response: response)
    return UbillingProvider(httpClient: http, now: { now })
}

private struct MockStatusProvider: StatusProviding {
    var snapshot: AlertsSnapshot?
    var error: (any Error)?

    func fetchAlerts() async throws -> AlertsSnapshot {
        if let error {
            throw error
        }
        guard let snapshot else {
            struct MissingSnapshot: Error {}
            throw MissingSnapshot()
        }
        return snapshot
    }
}

struct MockHTTPClient: HTTPClient {
    let data: Data
    let response: URLResponse

    func data(from _: URL) async throws -> (Data, URLResponse) {
        (data, response)
    }
}

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

        #expect(idle.title == "Checking…")
        #expect(quiet.title == "All Clear")
        #expect(alarm.title == "Alert Active")
        #expect(error.title == "Unavailable")

        #expect(idle.phase == .idle)
        #expect(quiet.phase == .quiet)
        #expect(alarm.phase == .alarm)
        #expect(error.phase == .error)
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
        let provider = MockStatusProvider { region in
            AlertStatusSnapshot(region: region, status: .quiet, checkedAt: Date(), source: "test")
        }
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
        #expect(
            AlertRegion(kind: .oblast(name: "Львівська область")).title
                == String(localized: "Львівська область")
        )
    }

    @Test
    @MainActor
    func controller_startsIdle_thenShowsQuiet() async {
        let checkedAt = Date(timeIntervalSince1970: 1)
        let provider = MockStatusProvider { region in
            AlertStatusSnapshot(
                region: region,
                status: .quiet,
                checkedAt: checkedAt,
                source: "test"
            )
        }
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
        let provider = MockStatusProvider { region in
            AlertStatusSnapshot(
                region: region,
                status: .alarm,
                checkedAt: checkedAt,
                source: "test"
            )
        }
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
        let provider = MockStatusProvider { _ in throw TestError() }
        let controller = StatusController(region: .kyivCity, provider: provider)

        await controller.refresh()

        #expect(controller.state == .error)
        #expect(controller.state.title == "Unavailable")
        #expect(controller.state.detailText == "Tap Refresh to try again")
    }

    @Test
    @MainActor
    func controller_updatesRegionTitle() {
        let provider = MockStatusProvider { region in
            AlertStatusSnapshot(region: region, status: .quiet, checkedAt: Date(), source: "test")
        }
        let controller = StatusController(region: .kyivCity, provider: provider)
        let oblast = AlertRegion(kind: .oblast(name: "Київська область"))

        controller.setRegion(oblast)
        #expect(controller.regionTitle == String(localized: "Київська область"))
    }

    @Test
    func provider_parsesKyivAlarmFromJSON() async throws {
        let provider = try makeProvider(json: kyivJSON(alertnow: true), now: Date(timeIntervalSince1970: 123))
        let snapshot = try await provider.fetchStatus(region: .kyivCity)
        #expect(snapshot.status == .alarm)
        #expect(snapshot.source == "test")
        #expect(snapshot.checkedAt == Date(timeIntervalSince1970: 123))
    }

    @Test
    func provider_parsesKyivQuietFromJSON() async throws {
        let provider = try makeProvider(json: kyivJSON(alertnow: false))
        let snapshot = try await provider.fetchStatus(region: .kyivCity)
        #expect(snapshot.status == .quiet)
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
        let region = AlertRegion(kind: .oblast(name: "Львівська область"))
        let snapshot = try await provider.fetchStatus(region: region)
        #expect(snapshot.status == .alarm)
        #expect(snapshot.region == region)
    }

    @Test
    func provider_throwsWhenRegionMissing() async throws {
        let provider = try makeProvider(json: kyivJSON(alertnow: true))
        let region = AlertRegion(kind: .oblast(name: "Одеська область"))
        await #expect(throws: UbillingError.missingRegionKey("Одеська область")) {
            _ = try await provider.fetchStatus(region: region)
        }
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
            _ = try await provider.fetchStatus(region: .kyivCity)
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

        let oblast = AlertRegion(kind: .oblast(name: "Харківська область"))
        store.save(oblast)
        #expect(store.load() == oblast)
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
    let statusForRegion: @Sendable (AlertRegion) async throws -> AlertStatusSnapshot

    func fetchStatus(region: AlertRegion) async throws -> AlertStatusSnapshot {
        try await statusForRegion(region)
    }
}

private struct MockHTTPClient: HTTPClient {
    let data: Data
    let response: URLResponse

    func data(from _: URL) async throws -> (Data, URLResponse) {
        (data, response)
    }
}

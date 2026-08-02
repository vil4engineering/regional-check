import CoreLocation
import DriveCheckKit
import Foundation
@testable import RegionalCheck
import Testing

@MainActor
struct RegionSelectionFollowTests {
    @Test
    func pin_disablesFollowAndSavesRegion() throws {
        let suite = "RegionSelectionFollowTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RegionStore(sharedStore: SharedStore(userDefaults: defaults))
        let selection = RegionSelection(store: store, geocoder: StubGeocoder())

        #expect(selection.followsLocation == true)
        selection.pin(.lviv)
        #expect(selection.followsLocation == false)
        #expect(selection.selectedRegion == .lviv)
        #expect(store.load() == .lviv)
        #expect(store.loadFollowsLocation() == false)
    }

    @Test
    func setFollowsLocation_persists() throws {
        let suite = "RegionSelectionFollowTests.persist.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RegionStore(sharedStore: SharedStore(userDefaults: defaults))
        let selection = RegionSelection(store: store, geocoder: StubGeocoder())

        selection.setFollowsLocation(false)
        let restored = RegionSelection(store: store, geocoder: StubGeocoder())
        #expect(restored.followsLocation == false)
    }

    @Test
    func updateFromLocation_ignoredWhenPinned() async throws {
        let suite = "RegionSelectionFollowTests.pinIgnore.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RegionStore(sharedStore: SharedStore(userDefaults: defaults))
        let geocoder = StubGeocoder(result: GeocodedAddress(
            countryCode: "UA",
            cityName: "Харків",
            administrativeAreaName: "Харківська область"
        ))
        let selection = RegionSelection(store: store, geocoder: geocoder)
        selection.pin(.lviv)
        selection.updateFromLocation(coordinate: CLLocationCoordinate2D(latitude: 50, longitude: 36))
        await Task.yield()
        await Task.yield()
        #expect(selection.selectedRegion == .lviv)
        #expect(geocoder.callCount == 0)
    }
}

private final class StubGeocoder: ReverseGeocoding, @unchecked Sendable {
    var result: GeocodedAddress?
    private(set) var callCount = 0

    init(result: GeocodedAddress? = nil) {
        self.result = result
    }

    func reverseGeocode(coordinate _: CLLocationCoordinate2D) async throws -> GeocodedAddress? {
        callCount += 1
        return result
    }
}

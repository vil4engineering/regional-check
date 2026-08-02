import CoreLocation
import Foundation
import Observation
import os

@MainActor
@Observable
final class RegionSelection {
    private static let log = Logger(subsystem: "vil4max.RegionalCheck", category: "Region")

    private(set) var selectedRegion: AlertRegion
    private(set) var followsLocation: Bool
    private(set) var shouldShowOutsideUkraineInfo = false

    private let store: RegionStore
    private let geocoder: any ReverseGeocoding
    private var isResolving = false
    private var didPresentOutsideUkraineThisSession = false

    init(
        store: RegionStore = .shared,
        geocoder: any ReverseGeocoding = MapKitReverseGeocoder()
    ) {
        self.store = store
        self.geocoder = geocoder
        selectedRegion = store.load() ?? .kyivCity
        followsLocation = store.loadFollowsLocation()
    }

    func acknowledgeOutsideUkraineInfo() {
        shouldShowOutsideUkraineInfo = false
    }

    func pin(_ region: AlertRegion) {
        followsLocation = false
        store.saveFollowsLocation(false)
        apply(region)
    }

    func setFollowsLocation(_ enabled: Bool) {
        followsLocation = enabled
        store.saveFollowsLocation(enabled)
    }

    func updateFromLocation(coordinate: CLLocationCoordinate2D) {
        guard followsLocation else { return }
        guard !isResolving else { return }
        isResolving = true

        Task {
            defer { isResolving = false }

            do {
                guard let address = try await geocoder.reverseGeocode(coordinate: coordinate) else {
                    return
                }
                guard address.countryCode == "UA" else {
                    applyOutsideUkraine()
                    return
                }

                guard let resolved = AlertRegionResolver.resolve(
                    cityName: address.cityName,
                    administrativeArea: address.administrativeAreaName
                ) else {
                    return
                }
                apply(resolved)
            } catch {
                Self.log.error("Reverse geocode failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    private func applyOutsideUkraine() {
        apply(.kyivCity)
        if !didPresentOutsideUkraineThisSession {
            didPresentOutsideUkraineThisSession = true
            shouldShowOutsideUkraineInfo = true
        }
    }

    private func apply(_ region: AlertRegion) {
        guard region != selectedRegion else { return }
        selectedRegion = region
        store.save(region)
    }
}

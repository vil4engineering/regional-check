import CoreLocation
import Foundation
import Observation
import os

@MainActor
@Observable
final class RegionSelection {
    private static let log = Logger(subsystem: "vil4max.RegionalCheck", category: "Region")

    private(set) var selectedRegion: AlertRegion
    private(set) var shouldShowOutsideUkraineInfo = false

    private let geocoder: any ReverseGeocoding
    private var isResolving = false
    private var didPresentOutsideUkraineThisSession = false

    init(geocoder: any ReverseGeocoding = MapKitReverseGeocoder()) {
        self.geocoder = geocoder
        selectedRegion = RegionStore.shared.load() ?? .kyivCity
    }

    func acknowledgeOutsideUkraineInfo() {
        shouldShowOutsideUkraineInfo = false
    }

    func updateFromLocation(coordinate: CLLocationCoordinate2D) {
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
        RegionStore.shared.save(region)
    }
}

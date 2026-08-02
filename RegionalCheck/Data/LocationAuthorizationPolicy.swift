import CoreLocation
import Foundation

enum LocationAuthorizationPolicy {
    static func isBlocked(_ status: CLAuthorizationStatus) -> Bool {
        status == .denied || status == .restricted
    }
}

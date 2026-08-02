import CoreLocation
@testable import RegionalCheck
import Testing

struct LocationAuthorizationPolicyTests {
    @Test
    func blockedStatuses() {
        #expect(LocationAuthorizationPolicy.isBlocked(.denied))
        #expect(LocationAuthorizationPolicy.isBlocked(.restricted))
        #expect(LocationAuthorizationPolicy.isBlocked(.authorizedWhenInUse) == false)
        #expect(LocationAuthorizationPolicy.isBlocked(.authorizedAlways) == false)
        #expect(LocationAuthorizationPolicy.isBlocked(.notDetermined) == false)
    }
}

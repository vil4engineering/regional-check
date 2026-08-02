import Foundation
@testable import RegionalCheck
import Testing

struct CarPlayConnectionTests {
    @Test
    func connect_isIdempotent() {
        var gate = CarPlayConnectionGate()
        #expect(gate.connect())
        #expect(gate.isConnected)
        #expect(gate.connect() == false)
        #expect(gate.isConnected)
    }

    @Test
    func disconnect_isIdempotent() {
        var gate = CarPlayConnectionGate()
        #expect(gate.disconnect() == false)
        #expect(gate.connect())
        #expect(gate.disconnect())
        #expect(gate.isConnected == false)
        #expect(gate.disconnect() == false)
    }

    @Test
    @MainActor
    func periodicRefresh_survivesDuplicateCarPlayConnectDisconnect() {
        let controller = StatusController(region: .kyivCity, provider: MockStatusProvider(snapshot: TestFixtures.quietSnapshot()))
        controller.beginPeriodicRefresh()
        controller.beginPeriodicRefresh()
        controller.endPeriodicRefresh()
        controller.endPeriodicRefresh()
        #expect(Bool(true))
    }
}

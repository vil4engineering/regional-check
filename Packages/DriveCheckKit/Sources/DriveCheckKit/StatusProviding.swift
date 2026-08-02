import Foundation

public protocol StatusProviding: Sendable {
    func fetchAlerts() async throws -> AlertsSnapshot
}

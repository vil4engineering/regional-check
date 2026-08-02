import Foundation

protocol StatusProviding: Sendable {
    func fetchAlerts() async throws -> AlertsSnapshot
}

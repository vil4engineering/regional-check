import Foundation

protocol StatusProviding: Sendable {
    func fetchStatus(region: AlertRegion) async throws -> AlertStatusSnapshot
}

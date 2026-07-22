import Foundation

struct AlertRegion: Hashable, Codable {
    enum Kind: Hashable, Codable {
        case kyivCity
        case oblast(name: String)
    }

    let kind: Kind

    static let kyivCity = AlertRegion(kind: .kyivCity)

    var title: String {
        switch kind {
        case .kyivCity:
            "Kyiv"
        case let .oblast(name):
            name
        }
    }
}

enum AlertStatus: Equatable {
    case quiet
    case alarm
}

struct AlertStatusSnapshot: Equatable {
    let region: AlertRegion
    let status: AlertStatus
    let checkedAt: Date
    let source: String
}

protocol StatusProviding: Sendable {
    func fetchStatus(region: AlertRegion) async throws -> AlertStatusSnapshot
}

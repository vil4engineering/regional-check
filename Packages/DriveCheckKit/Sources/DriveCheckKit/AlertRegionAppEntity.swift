import AppIntents
import Foundation

extension AlertRegion: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("intent.region.type", bundle: .module))
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    public static let defaultQuery = AlertRegionEntityQuery()
}

public struct AlertRegionEntityQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [AlertRegion] {
        identifiers.compactMap { AlertRegion(rawValue: $0) }
    }

    public func suggestedEntities() async throws -> [AlertRegion] {
        AlertRegion.allCases
    }
}

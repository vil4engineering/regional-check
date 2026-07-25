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
            String(localized: "Kyiv")
        case let .oblast(name):
            String(localized: String.LocalizationValue(name))
        }
    }
}

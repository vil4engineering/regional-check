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
            Self.localizedOblastTitle(name)
        }
    }

    private static func localizedOblastTitle(_ name: String) -> String {
        switch name {
        case "Автономна Республіка Крим":
            String(localized: "Автономна Республіка Крим")
        case "Вінницька область":
            String(localized: "Вінницька область")
        case "Волинська область":
            String(localized: "Волинська область")
        case "Дніпропетровська область":
            String(localized: "Дніпропетровська область")
        case "Донецька область":
            String(localized: "Донецька область")
        case "Житомирська область":
            String(localized: "Житомирська область")
        case "Закарпатська область":
            String(localized: "Закарпатська область")
        case "Запорізька область":
            String(localized: "Запорізька область")
        case "Івано-Франківська область":
            String(localized: "Івано-Франківська область")
        case "Київська область":
            String(localized: "Київська область")
        case "Кіровоградська область":
            String(localized: "Кіровоградська область")
        case "Луганська область":
            String(localized: "Луганська область")
        case "Львівська область":
            String(localized: "Львівська область")
        case "Миколаївська область":
            String(localized: "Миколаївська область")
        case "Одеська область":
            String(localized: "Одеська область")
        case "Полтавська область":
            String(localized: "Полтавська область")
        case "Рівненська область":
            String(localized: "Рівненська область")
        case "Сумська область":
            String(localized: "Сумська область")
        case "Тернопільська область":
            String(localized: "Тернопільська область")
        case "Харківська область":
            String(localized: "Харківська область")
        case "Херсонська область":
            String(localized: "Херсонська область")
        case "Хмельницька область":
            String(localized: "Хмельницька область")
        case "Черкаська область":
            String(localized: "Черкаська область")
        case "Чернівецька область":
            String(localized: "Чернівецька область")
        case "Чернігівська область":
            String(localized: "Чернігівська область")
        case "м. Севастополь":
            String(localized: "м. Севастополь")
        default:
            name
        }
    }
}

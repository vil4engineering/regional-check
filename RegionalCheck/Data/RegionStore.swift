import Foundation

struct RegionStore {
    static let shared = RegionStore(userDefaults: .standard)

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func load() -> AlertRegion? {
        if let data = userDefaults.data(forKey: Keys.v2Key),
           let region = try? JSONDecoder().decode(AlertRegion.self, from: data)
        {
            return region
        }

        guard let legacyData = userDefaults.data(forKey: Keys.v1Key),
              let legacy = try? JSONDecoder().decode(LegacyAlertRegion.self, from: legacyData),
              let region = legacy.resolved
        else {
            return nil
        }

        save(region)
        userDefaults.removeObject(forKey: Keys.v1Key)
        return region
    }

    func save(_ region: AlertRegion) {
        guard let data = try? JSONEncoder().encode(region) else { return }
        userDefaults.set(data, forKey: Keys.v2Key)
    }

    private enum Keys {
        static let v1Key = "selected_region_v1"
        static let v2Key = "selected_region_v2"
    }
}

private struct LegacyAlertRegion: Decodable {
    enum Kind: Decodable {
        case kyivCity
        case oblast(name: String)
    }

    let kind: Kind

    var resolved: AlertRegion? {
        switch kind {
        case .kyivCity:
            .kyivCity
        case let .oblast(name):
            AlertRegion.from(apiKey: name) ?? .kyivCity
        }
    }
}

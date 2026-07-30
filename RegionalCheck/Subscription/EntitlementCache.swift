import Foundation

struct EntitlementCache: EntitlementCaching {
    private nonisolated(unsafe) let defaults: UserDefaults
    private let key = "subscription.entitlement.v1"

    init(userDefaults: UserDefaults = .standard) {
        defaults = userDefaults
    }

    func load() -> EntitlementSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(EntitlementSnapshot.self, from: data)
    }

    func save(_ snapshot: EntitlementSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

import Foundation

enum TestDefaults {
    static func withTemporaryDefaults<T>(
        suiteName: String = "RegionalCheckTests.\(UUID().uuidString)",
        _ operation: (UserDefaults) throws -> T
    ) rethrows -> T {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Missing UserDefaults suite \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        return try operation(defaults)
    }

    static func withTemporaryDefaults<T>(
        suiteName: String = "RegionalCheckTests.\(UUID().uuidString)",
        _ operation: (UserDefaults) async throws -> T
    ) async rethrows -> T {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Missing UserDefaults suite \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        return try await operation(defaults)
    }
}

enum TestLocale {
    static func english<T>(_ operation: () throws -> T) rethrows -> T {
        let previous = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
        }
        return try operation()
    }

    static func english<T>(_ operation: () async throws -> T) async rethrows -> T {
        let previous = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
        }
        return try await operation()
    }
}

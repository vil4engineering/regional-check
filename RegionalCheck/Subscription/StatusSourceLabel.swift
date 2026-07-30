import Foundation

enum StatusSourceLabel {
    static func displayName(for rawSource: String?) -> String {
        guard let rawSource, !rawSource.isEmpty else {
            return String(localized: "status.source.external")
        }
        let normalized = rawSource.lowercased()
        if normalized.contains("mørk") || normalized.contains("mork") || normalized.contains("skogen") {
            return String(localized: "status.source.alertFeed")
        }
        if normalized == "test" || normalized == "preview" {
            return String(localized: "status.source.alertFeed")
        }
        return String(localized: "status.source.external")
    }
}

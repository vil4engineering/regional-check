import AppIntents
import Foundation

public struct CheckAlertStatusIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.check.title"

    @Parameter(title: "intent.region.parameter")
    public var region: AlertRegion?

    public init() {}

    public init(region: AlertRegion?) {
        self.region = region
    }

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = SharedStore.shared
        let selected = region ?? store.loadRegion() ?? .kyivCity
        let regionTitle = selected.title
        guard let snapshot = store.loadSnapshot() else {
            let checking = String(localized: "intent.answer.checking", bundle: .module)
            return .result(dialog: IntentDialog(stringLiteral: "\(regionTitle): \(checking)"))
        }
        let statusKey: String.LocalizationValue = switch snapshot.status(for: selected) {
        case .alarm: "Alert Active"
        case .quiet: "All Clear"
        case nil: "Region Unavailable"
        }
        let status = String(localized: statusKey, bundle: .module)
        let dialog = String(
            format: String(localized: "intent.answer.free.dialog", bundle: .module),
            regionTitle,
            status
        )
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

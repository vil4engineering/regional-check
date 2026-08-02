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
        let answer = AlertStatusAnswerBuilder.answer(for: selected, store: store)
        return .result(dialog: IntentDialog(stringLiteral: answer.dialog))
    }
}

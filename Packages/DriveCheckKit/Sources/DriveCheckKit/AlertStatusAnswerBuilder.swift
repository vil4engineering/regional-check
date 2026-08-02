import Foundation

public enum AlertStatusAnswerBuilder {
    public struct Answer: Equatable, Sendable {
        public let spoken: String
        public let dialog: String

        public init(spoken: String, dialog: String) {
            self.spoken = spoken
            self.dialog = dialog
        }
    }

    public static func answer(for region: AlertRegion, store: SharedStore) -> Answer {
        guard let snapshot = store.loadSnapshot() else {
            let regionTitle = region.title
            let spoken = String(localized: "intent.answer.checking", bundle: .module)
            return Answer(
                spoken: spoken,
                dialog: "\(regionTitle): \(spoken)"
            )
        }
        let regionTitle = region.title
        let checkedAt = snapshot.checkedAt
        let statusKey: String.LocalizationValue = switch snapshot.status(for: region) {
        case .alarm: "Alert Active"
        case .quiet: "All Clear"
        case nil: "Region Unavailable"
        }
        let status = String(localized: statusKey, bundle: .module)
        if store.loadIsPro() {
            let time = checkedAt.formatted(date: .omitted, time: .shortened)
            let spoken = String(
                format: String(localized: "intent.answer.pro.spoken", bundle: .module),
                regionTitle,
                status,
                snapshot.source,
                time
            )
            let dialog = String(
                format: String(localized: "intent.answer.pro.dialog", bundle: .module),
                regionTitle,
                status,
                snapshot.source,
                time
            )
            return Answer(spoken: spoken, dialog: dialog)
        }
        let spoken = String(
            format: String(localized: "intent.answer.free.spoken", bundle: .module),
            regionTitle,
            status
        )
        let dialog = String(
            format: String(localized: "intent.answer.free.dialog", bundle: .module),
            regionTitle,
            status
        )
        return Answer(spoken: spoken, dialog: dialog)
    }
}

import Foundation

public struct ControlStatusValue: Equatable, Sendable {
    public let phase: DriveCheckActivityPhase
    public let regionTitle: String

    public init(phase: DriveCheckActivityPhase, regionTitle: String) {
        self.phase = phase
        self.regionTitle = regionTitle
    }
}

public enum ControlStatusValueBuilder {
    public static func value(from store: SharedStore) -> ControlStatusValue {
        let presentation = WidgetTimelineBuilder.presentation(store: store)
        return ControlStatusValue(phase: presentation.phase, regionTitle: presentation.regionTitle)
    }
}

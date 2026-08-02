import AppIntents
import Foundation
import WidgetKit

public struct RefreshStatusIntent: AppIntent {
    public static let title: LocalizedStringResource = "intent.refresh.title"

    public init() {}

    public func perform() async throws -> some IntentResult {
        let snapshot = try await UbillingProvider().fetchAlerts()
        SharedStore.shared.saveSnapshot(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

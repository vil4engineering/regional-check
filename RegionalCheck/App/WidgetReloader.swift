import WidgetKit

enum WidgetReloader {
    static func reloadAllTimelines() {
        guard !HostProcess.isUnitTesting else { return }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

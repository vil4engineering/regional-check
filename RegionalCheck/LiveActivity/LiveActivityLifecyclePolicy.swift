import Foundation

enum LiveActivityLifecyclePolicy {
    enum Action: Equatable {
        case none
        case start
        case update
        case terminate
    }

    static func nextAction(canRun: Bool, hasClients: Bool, hasActivity: Bool) -> Action {
        if !canRun || !hasClients {
            return hasActivity ? .terminate : .none
        }
        return hasActivity ? .update : .start
    }
}

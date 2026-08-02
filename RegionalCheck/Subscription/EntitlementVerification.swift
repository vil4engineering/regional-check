import Foundation

enum EntitlementVerification: Equatable, Sendable {
    case active(EntitlementSnapshot)
    case none
    case unverified

    var snapshotIfActive: EntitlementSnapshot? {
        if case let .active(snapshot) = self {
            return snapshot
        }
        return nil
    }
}

enum RestoreOutcome: Equatable, Sendable {
    case restored
    case empty
    case failed
}

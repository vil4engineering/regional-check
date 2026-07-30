import Foundation

@MainActor
protocol LiveActivityControlling: AnyObject {
    func beginPhoneForegroundSession()
    func endPhoneForegroundSession()
    func beginCarPlaySession()
    func endCarPlaySession()
    func update(phase: DriveCheckActivityPhase, regionTitle: String, checkedAt: Date?, sourceLabel: String)
    func endAll()
}

enum LiveActivitySessionClient: Hashable {
    case phoneForeground
    case carPlay
}

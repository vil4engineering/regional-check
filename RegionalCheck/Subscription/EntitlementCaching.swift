import Foundation

protocol EntitlementCaching: Sendable {
    func load() -> EntitlementSnapshot?
    func save(_ snapshot: EntitlementSnapshot)
    func clear()
}

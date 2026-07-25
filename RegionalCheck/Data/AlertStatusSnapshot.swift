import Foundation

enum AlertStatus: Equatable {
    case quiet
    case alarm
}

struct AlertStatusSnapshot: Equatable {
    let region: AlertRegion
    let status: AlertStatus
    let checkedAt: Date
    let source: String
}

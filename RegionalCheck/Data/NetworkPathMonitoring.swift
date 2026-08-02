import Foundation
import Network

struct NetworkPathSnapshot: Equatable, Sendable {
    var isExpensive: Bool
    var isConstrained: Bool
}

@MainActor
protocol NetworkPathMonitoring: AnyObject {
    var currentPath: NetworkPathSnapshot { get }
    func start()
}

@MainActor
final class LiveNetworkPathMonitor: NetworkPathMonitoring {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "vil4max.RegionalCheck.NetworkPath")
    private(set) var currentPath = NetworkPathSnapshot(isExpensive: false, isConstrained: false)

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.currentPath = NetworkPathSnapshot(
                    isExpensive: path.isExpensive,
                    isConstrained: path.isConstrained
                )
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

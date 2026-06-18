import Network

final class NetworkReachabilityMonitor {
    static let shared = NetworkReachabilityMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.mediguide.network", qos: .utility)
    // Optimistic default: assume reachable until the monitor delivers its first update.
    // Without this, currentPath.status is unsatisfied for a brief window after start(),
    // causing every API call during that window to fall back unnecessarily.
    private var latestStatus: NWPath.Status = .satisfied

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.latestStatus = path.status
        }
        monitor.start(queue: queue)
    }

    var isReachable: Bool { latestStatus == .satisfied }
}

import Network
import Combine

class NetworkMonitor: ObservableObject {
    // Publisher that the rest of the app can subscribe to
    let connectivityChanged = PassthroughSubject<Bool, Never>()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetGlow.NetworkMonitor")
    private var wasConnected: Bool? = nil

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            
            // Only notify if the status actually changed
            if self?.wasConnected != isConnected {
                self?.wasConnected = isConnected
                DispatchQueue.main.async {
                    self?.connectivityChanged.send(isConnected)
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

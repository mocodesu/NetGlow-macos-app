import Foundation
import Network
import Combine

enum ConnectionStatus: Equatable {
    case connected
    case disconnected
    case captivePortal

    var isConnected: Bool {
        self != .disconnected
    }
}

class NetworkMonitor: ObservableObject {
    let statusChanged = PassthroughSubject<ConnectionStatus, Never>()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetGlow.NetworkMonitor")
    private var lastStatus: ConnectionStatus?

    // Generation token: invalidates stale async responses
    private var generation: UInt64 = 0
    private var captiveCheckTask: URLSessionDataTask?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let isSatisfied = path.status == .satisfied

            // Invalidate any in-flight captive check and cancel it
            self.generation &+= 1
            let currentGen = self.generation
            self.captiveCheckTask?.cancel()
            self.captiveCheckTask = nil

            if isSatisfied {
                self.checkCaptivePortal { [weak self] isCaptive in
                    guard let self = self else { return }
                    // Bail if another path update happened while we were checking
                    guard self.generation == currentGen else { return }
                    let status: ConnectionStatus = isCaptive ? .captivePortal : .connected
                    self.publish(status)
                }
            } else {
                self.publish(.disconnected)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        captiveCheckTask?.cancel()
    }

    private func publish(_ status: ConnectionStatus) {
        DispatchQueue.main.async {
            guard self.lastStatus != status else { return }
            self.lastStatus = status
            self.statusChanged.send(status)
        }
    }

    private func checkCaptivePortal(completion: @escaping (Bool) -> Void) {
        let shouldCheck = UserDefaults.standard.bool(forKey: PreferenceKeys.checkCaptivePortal)
        guard shouldCheck else {
            completion(false)
            return
        }

        guard let url = URL(string: "http://captive.apple.com/hotspot-detect.html") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil,
                  let data = data,
                  let body = String(data: data, encoding: .utf8) else {
                completion(false)
                return
            }
            completion(!body.contains("Success"))
        }
        captiveCheckTask = task
        task.resume()
    }
}

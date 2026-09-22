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

final class NetworkMonitor: ObservableObject {
    let statusChanged = PassthroughSubject<ConnectionStatus, Never>()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetGlow.NetworkMonitor")
    private var lastStatus: ConnectionStatus?

    // Generation token: invalidates stale async responses
    private var generation: UInt64 = 0
    private var probeTask: URLSessionDataTask?
    private var periodicTimer: DispatchSourceTimer?

    // State owned by `queue`
    private var pathSatisfied = false
    private var consecutiveProbeFailures = 0

    /// How often we actively probe the internet for real reachability.
    /// NWPathMonitor alone can't tell us the ISP is down while Wi-Fi is up,
    /// so we poll on a timer in addition to reacting to path changes.
    private let probeInterval: TimeInterval = 3.0

    /// Number of consecutive probe failures required before reporting
    /// `.disconnected`. The AppDelegate's grace period already debounces
    /// short blips, so 1 is fine here.
    private let failureThreshold = 1

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.pathSatisfied = (path.status == .satisfied)
            if !self.pathSatisfied {
                self.consecutiveProbeFailures = 0
            }
            // A path change is a strong hint something changed —
            // probe immediately instead of waiting for the next tick.
            self.runProbe()
        }
        monitor.start(queue: queue)
        startPeriodicTimer()
    }

    deinit {
        monitor.cancel()
        probeTask?.cancel()
        periodicTimer?.cancel()
    }

    // MARK: - Periodic probing

    private func startPeriodicTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + probeInterval, repeating: probeInterval)
        timer.setEventHandler { [weak self] in
            self?.runProbe()
        }
        timer.resume()
        periodicTimer = timer
    }

    // MARK: - Probe logic (all on `queue`)

    private func runProbe() {
        // If the OS says there's no usable path, we're done — no need to
        // spend a network round-trip confirming the obvious.
        guard pathSatisfied else {
            publish(.disconnected)
            return
        }

        // Invalidate any in-flight probe so we only act on the latest one.
        generation &+= 1
        let currentGen = generation
        probeTask?.cancel()
        probeTask = nil

        performProbe { [weak self] result in
            guard let self = self else { return }
            self.queue.async {
                guard self.generation == currentGen else { return }

                switch result {
                case .reachable(let isCaptive):
                    self.consecutiveProbeFailures = 0
                    self.publish(isCaptive ? .captivePortal : .connected)

                case .unreachable:
                    self.consecutiveProbeFailures += 1
                    if self.consecutiveProbeFailures >= self.failureThreshold {
                        self.publish(.disconnected)
                    }
                }
            }
        }
    }

    private enum ProbeResult {
        case reachable(isCaptive: Bool)
        case unreachable
    }

    /// Hits Apple's standard captive-portal probe endpoint.
    ///
    /// - Returns a small HTML body containing `"Success"` when the internet
    ///   is fully reachable.
    /// - Returns a redirect / different body when behind a captive portal.
    /// - Errors out (or times out) when the internet is actually down, even
    ///   if the Wi-Fi/Ethernet link is still up.
    private func performProbe(completion: @escaping (ProbeResult) -> Void) {
        guard let url = URL(string: "http://captive.apple.com/hotspot-detect.html") else {
            completion(.unreachable)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil,
                  let http = response as? HTTPURLResponse,
                  http.statusCode == 200,
                  let data = data,
                  let body = String(data: data, encoding: .utf8) else {
                completion(.unreachable)
                return
            }

            let checkCaptive = UserDefaults.standard.bool(forKey: PreferenceKeys.checkCaptivePortal)
            let isCaptive = checkCaptive && !body.contains("Success")
            completion(.reachable(isCaptive: isCaptive))
        }
        probeTask = task
        task.resume()
    }

    // MARK: - Publishing

    private func publish(_ status: ConnectionStatus) {
        DispatchQueue.main.async {
            guard self.lastStatus != status else { return }
            self.lastStatus = status
            self.statusChanged.send(status)
        }
    }
}
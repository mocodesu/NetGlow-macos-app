import Foundation
import Combine

struct ConnectionEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let statusRaw: String

    var status: ConnectionStatus {
        switch statusRaw {
        case "connected": return .connected
        case "captivePortal": return .captivePortal
        default: return .disconnected
        }
    }
}

class ConnectionHistory: ObservableObject {
    static let shared = ConnectionHistory()

    @Published private(set) var events: [ConnectionEvent] = []
    private let storageKey = "connectionEvents"
    private let maxEvents = 2000

    private init() {
        load()
    }

    func record(_ status: ConnectionStatus) {
        let raw: String
        switch status {
        case .connected: raw = "connected"
        case .captivePortal: raw = "captivePortal"
        case .disconnected: raw = "disconnected"
        }
        events.append(ConnectionEvent(id: UUID(), timestamp: Date(), statusRaw: raw))
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        save()
    }

    func clear() {
        events.removeAll()
        save()
    }

    var uptimeToday: Double {
        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.timestamp >= today }
        guard let first = todayEvents.first else { return 1.0 }

        var connectedSeconds: TimeInterval = 0
        var currentStart: Date? = first.status.isConnected ? first.timestamp : nil

        for event in todayEvents.dropFirst() {
            if event.status.isConnected, currentStart == nil {
                currentStart = event.timestamp
            } else if !event.status.isConnected, let start = currentStart {
                connectedSeconds += event.timestamp.timeIntervalSince(start)
                currentStart = nil
            }
        }
        if let start = currentStart {
            connectedSeconds += Date().timeIntervalSince(start)
        }

        let totalSeconds = Date().timeIntervalSince(today)
        guard totalSeconds > 0 else { return 1.0 }
        return min(1.0, connectedSeconds / totalSeconds)
    }

    var outagesToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let todayEvents = events.filter { $0.timestamp >= today }
        var count = 0
        var wasConnected: Bool? = nil
        for event in todayEvents {
            if wasConnected == true && !event.status.isConnected {
                count += 1
            }
            wasConnected = event.status.isConnected
        }
        return count
    }

    private func save() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ConnectionEvent].self, from: data) {
            events = decoded
        }
    }
}

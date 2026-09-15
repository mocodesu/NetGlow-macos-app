import SwiftUI

struct PreferencesView: View {
    var body: some View {
        TabView {
            GeneralPreferences()
                .tabItem { Label("General", systemImage: "gear") }
            AppearancePreferences()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
        }
        .frame(width: 520, height: 400)
    }
}

struct GeneralPreferences: View {
    @AppStorage(PreferenceKeys.showNotifications) private var showNotifications = true
    @AppStorage(PreferenceKeys.playSounds) private var playSounds = false
    @AppStorage(PreferenceKeys.showOnAllScreens) private var showOnAllScreens = true
    @AppStorage(PreferenceKeys.checkCaptivePortal) private var checkCaptivePortal = true
    @AppStorage(PreferenceKeys.gracePeriod) private var gracePeriod: Double = 2.5
    @AppStorage(PreferenceKeys.flashDuration) private var flashDuration: Double = 2.0

    var body: some View {
        Form {
            Section("Alerts") {
                Toggle("Show notifications", isOn: $showNotifications)
                Toggle("Play sounds", isOn: $playSounds)
                Toggle("Show overlay on all displays", isOn: $showOnAllScreens)
                Toggle("Detect captive portals", isOn: $checkCaptivePortal)
            }
            Section("Timing") {
                HStack {
                    Text("Grace period")
                    Slider(value: $gracePeriod, in: 0...10, step: 0.5)
                    Text(String(format: "%.1fs", gracePeriod))
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
                HStack {
                    Text("Green flash duration")
                    Slider(value: $flashDuration, in: 0.5...10, step: 0.5)
                    Text(String(format: "%.1fs", flashDuration))
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding()
    }
}

struct AppearancePreferences: View {
    @AppStorage(PreferenceKeys.connectedColorHex) private var connectedColorHex = "#34C759"
    @AppStorage(PreferenceKeys.disconnectedColorHex) private var disconnectedColorHex = "#FF3B30"
    @AppStorage(PreferenceKeys.captivePortalColorHex) private var captivePortalColorHex = "#FF9500"
    @AppStorage(PreferenceKeys.borderWidth) private var borderWidth: Double = 12.0

    var body: some View {
        Form {
            Section("Colors") {
                ColorPicker("Connected", selection: Binding(
                    get: { Color(hex: connectedColorHex) },
                    set: { connectedColorHex = $0.hexString }
                ))
                ColorPicker("Disconnected", selection: Binding(
                    get: { Color(hex: disconnectedColorHex) },
                    set: { disconnectedColorHex = $0.hexString }
                ))
                ColorPicker("Captive portal", selection: Binding(
                    get: { Color(hex: captivePortalColorHex) },
                    set: { captivePortalColorHex = $0.hexString }
                ))
            }
            Section("Border") {
                HStack {
                    Text("Thickness")
                    Slider(value: $borderWidth, in: 2...40, step: 1)
                    Text(String(format: "%.0fpt", borderWidth))
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding()
    }
}

struct HistoryView: View {
    @ObservedObject private var history = ConnectionHistory.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                statCard(title: "Uptime today",
                         value: String(format: "%.1f%%", history.uptimeToday * 100))
                statCard(title: "Outages today",
                         value: "\(history.outagesToday)")
                statCard(title: "Total events",
                         value: "\(history.events.count)")
            }
            .padding(.horizontal)

            List(history.events.reversed().prefix(100)) { event in
                HStack {
                    Circle()
                        .fill(colorFor(event.status))
                        .frame(width: 8, height: 8)
                    Text(labelFor(event.status))
                    Spacer()
                    Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }

            HStack {
                Spacer()
                Button("Clear History") {
                    history.clear()
                }
                .padding()
            }
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func colorFor(_ status: ConnectionStatus) -> Color {
        switch status {
        case .connected:
            return Color(hex: UserDefaults.standard.string(forKey: PreferenceKeys.connectedColorHex) ?? "#34C759")
        case .disconnected:
            return Color(hex: UserDefaults.standard.string(forKey: PreferenceKeys.disconnectedColorHex) ?? "#FF3B30")
        case .captivePortal:
            return Color(hex: UserDefaults.standard.string(forKey: PreferenceKeys.captivePortalColorHex) ?? "#FF9500")
        }
    }

    private func labelFor(_ status: ConnectionStatus) -> String {
        switch status {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .captivePortal: return "Captive Portal"
        }
    }
}

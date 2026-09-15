import SwiftUI
import Combine
import AppKit
import UserNotifications

@main
struct NetGlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        Preferences.registerDefaults()
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let networkMonitor = NetworkMonitor()
    let history = ConnectionHistory.shared

    private var cancellables = Set<AnyCancellable>()
    private var hideTimer: Timer?
    private var pendingDisconnectTimer: Timer?
    private var statusItem: NSStatusItem?
    private var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        requestNotificationPermission()

        networkMonitor.statusChanged
            .sink { [weak self] status in
                self?.handleStatusChange(status)
            }
            .store(in: &cancellables)
    }

    // MARK: - Status handling

    private func handleStatusChange(_ status: ConnectionStatus) {
        pendingDisconnectTimer?.invalidate()
        pendingDisconnectTimer = nil

        switch status {
        case .connected:
            history.record(.connected)
            updateStatusIcon(.connected)
            flash(.connected)

        case .captivePortal:
            history.record(.captivePortal)
            updateStatusIcon(.captivePortal)
            flash(.captivePortal)

        case .disconnected:
            let grace = UserDefaults.standard.double(forKey: PreferenceKeys.gracePeriod)
            if grace <= 0 {
                applyDisconnect()
            } else {
                pendingDisconnectTimer = Timer.scheduledTimer(
                    withTimeInterval: grace, repeats: false
                ) { [weak self] _ in
                    self?.applyDisconnect()
                }
            }
        }
    }

    private func applyDisconnect() {
        history.record(.disconnected)
        updateStatusIcon(.disconnected)
        OverlayWindowManager.shared.show(
            color: color(for: .disconnected),
            opacity: 0.85
        )
        notify(.disconnected)
        playSound(.disconnected)
    }

    private func flash(_ status: ConnectionStatus) {
        let duration = UserDefaults.standard.double(forKey: PreferenceKeys.flashDuration)
        OverlayWindowManager.shared.show(
            color: color(for: status),
            opacity: 0.85
        )
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            OverlayWindowManager.shared.hide()
        }
        notify(status)
        playSound(status)
    }

    private func color(for status: ConnectionStatus) -> Color {
        let key: String
        switch status {
        case .connected: key = PreferenceKeys.connectedColorHex
        case .disconnected: key = PreferenceKeys.disconnectedColorHex
        case .captivePortal: key = PreferenceKeys.captivePortalColorHex
        }
        let hex = UserDefaults.standard.string(forKey: key) ?? "#000000"
        return Color(hex: hex)
    }

    // MARK: - Menu bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let menu = NSMenu()
        let statusItemTitle = NSMenuItem(title: "Status: Unknown", action: nil, keyEquivalent: "")
        statusItemTitle.isEnabled = false
        statusItemTitle.tag = 100
        menu.addItem(statusItemTitle)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences…",
                                action: #selector(openPreferences),
                                keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NetGlow",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        statusItem?.menu = menu
        updateStatusIcon(.connected)
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func updateStatusIcon(_ status: ConnectionStatus) {
        let symbolName: String
        let tint: NSColor
        let label: String

        switch status {
        case .connected:
            symbolName = "wifi"
            tint = .systemGreen
            label = "Connected"
        case .disconnected:
            symbolName = "wifi.slash"
            tint = .systemRed
            label = "Disconnected"
        case .captivePortal:
            symbolName = "wifi.exclamationmark"
            tint = .systemOrange
            label = "Captive Portal"
        }

        let config = NSImage.SymbolConfiguration(paletteColors: [tint])
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)?
            .withSymbolConfiguration(config)
        statusItem?.button?.image = image

        if let menu = statusItem?.menu,
           let item = menu.item(withTag: 100) {
            item.title = "Status: \(label)"
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notify(_ status: ConnectionStatus) {
        guard UserDefaults.standard.bool(forKey: PreferenceKeys.showNotifications) else { return }

        let content = UNMutableNotificationContent()
        switch status {
        case .connected:
            content.title = "Internet Restored"
            content.body = "You're back online."
            content.sound = .default
        case .disconnected:
            content.title = "Internet Lost"
            content.body = "NetGlow detected a dropped connection."
            content.sound = .defaultCritical
        case .captivePortal:
            content.title = "Captive Portal Detected"
            content.body = "Sign in to the Wi-Fi network to get online."
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Sounds

    private func playSound(_ status: ConnectionStatus) {
        guard UserDefaults.standard.bool(forKey: PreferenceKeys.playSounds) else { return }

        switch status {
        case .connected:
            // Light, pleasant confirmation
            NSSound(named: "Glass")?.play()

        case .disconnected:
            // Two-hit failure indicator: the classic descending "wah-wah" tone,
            // repeated quickly so it's unmistakable without being obnoxious.
            NSSound(named: "Funk")?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                NSSound(named: "Funk")?.play()
            }

        case .captivePortal:
            // Neutral attention ping
            NSSound(named: "Ping")?.play()
        }
    }
}

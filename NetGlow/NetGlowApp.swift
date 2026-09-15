import SwiftUI
import ServiceManagement
import Combine

@main
struct NetGlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We don't need a main window; the app runs in background.
        // We can use a Settings scene if we want a preferences window later.
        Settings {
            Text("NetGlow is running in the background.")
                .padding()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let networkMonitor = NetworkMonitor()
    private var hideTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Subscribe to connectivity changes
        networkMonitor.connectivityChanged
            .sink { [weak self] isConnected in
                self?.handleConnectivityChange(isConnected: isConnected)
            }
            .store(in: &cancellables)
        
        // Register for launch at login
        registerLoginItem()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func handleConnectivityChange(isConnected: Bool) {
        // Cancel any pending hide timer
        hideTimer?.invalidate()
        
        if isConnected {
            // Internet is back: Flash Green
            OverlayWindowManager.shared.show(color: .green, opacity: 0.8)
            
            // Fade out after 2 seconds
            hideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                withAnimation(.easeOut(duration: 1.0)) {
                    OverlayWindowManager.shared.hide()
                }
            }
        } else {
            // Internet is out: Show Red (persistent)
            OverlayWindowManager.shared.show(color: .red, opacity: 0.8)
            // No timer; it stays until connection returns
        }
    }
    
    private func registerLoginItem() {
        do {
            // Use SMAppService to register the main app as a login item
            // This works for sandboxed and non-sandboxed apps on macOS 13+
            try SMAppService.mainApp.register()
            print("Registered for launch at login.")
        } catch {
            print("Failed to register login item: \(error)")
        }
    }
}

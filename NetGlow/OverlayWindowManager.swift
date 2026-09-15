import AppKit
import SwiftUI

class OverlayWindowManager {
    static let shared = OverlayWindowManager()
    
    private var window: NSWindow?
    private var hostingView: NSHostingView<EdgeOverlayView>?
    
    private init() {}

    func show(color: Color, opacity: Double) {
        // If window doesn't exist, create it covering the main screen
        if window == nil {
            guard let screen = NSScreen.main else { return }
            
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver // Above almost everything
            window.backgroundColor = .clear
            window.isOpaque = false
            window.ignoresMouseEvents = true // Click-through
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            let view = NSHostingView(rootView: EdgeOverlayView(color: color, opacity: 0))
            window.contentView = view
            
            self.window = window
            self.hostingView = view
        }
        
        // Update the view content
        hostingView?.rootView = EdgeOverlayView(color: color, opacity: opacity)
        
        // Show window without activating the app
        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }
}

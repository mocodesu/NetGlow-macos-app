import AppKit
import SwiftUI

class OverlayWindowManager {
    static let shared = OverlayWindowManager()

    private var windows: [NSWindow] = []
    private var hostingViews: [NSHostingView<EdgeOverlayView>] = []

    private init() {}

    func show(color: Color, opacity: Double) {
        let screens = NSScreen.screens
        let lineWidth = CGFloat(UserDefaults.standard.double(forKey: PreferenceKeys.borderWidth))
        let allScreens = UserDefaults.standard.bool(forKey: PreferenceKeys.showOnAllScreens)
        let targetScreens = allScreens ? screens : Array(screens.prefix(1))

        if windows.count != targetScreens.count {
            teardown()
            buildWindows(for: targetScreens)
        }

        for (index, window) in windows.enumerated() {
            let view = EdgeOverlayView(color: color, opacity: opacity, lineWidth: lineWidth)
            if index < hostingViews.count {
                hostingViews[index].rootView = view
            }
            window.orderFrontRegardless()
        }
    }

    func hide() {
        for window in windows {
            window.orderOut(nil)
        }
    }

    func teardown() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        hostingViews.removeAll()
    }

    private func buildWindows(for screens: [NSScreen]) {
        for screen in screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let hostingView = NSHostingView(rootView: EdgeOverlayView(
                color: .clear,
                opacity: 0,
                lineWidth: 12
            ))
            window.contentView = hostingView

            windows.append(window)
            hostingViews.append(hostingView)
        }
    }
}

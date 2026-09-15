import SwiftUI

struct EdgeOverlayView: View {
    var color: Color
    var opacity: Double
    var lineWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .strokeBorder(color, lineWidth: lineWidth)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .opacity(opacity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

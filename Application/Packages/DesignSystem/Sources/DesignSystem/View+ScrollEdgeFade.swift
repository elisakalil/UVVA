import SwiftUI

extension View {
    /// Clips a scroll view to its own frame and fades its top edge, so content never runs under the status bar.
    public func scrollEdgeFade(_ height: CGFloat = 24) -> some View {
        mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: height)
                Color.black
            }
        }
    }
}

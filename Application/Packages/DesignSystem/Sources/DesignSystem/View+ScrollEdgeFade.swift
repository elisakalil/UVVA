import SwiftUI

extension View {
    /// Clips a scroll view to its own frame and fades its top edge, so content never runs under the status bar.
    /// `throughBottomInset` keeps the content showing under a bar inset at the bottom, like the tab bar.
    public func scrollEdgeFade(_ height: CGFloat = 24, throughBottomInset: Bool = false) -> some View {
        mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: height)
                Color.black
            }
            .ignoresSafeArea(edges: throughBottomInset ? .bottom : [])
        }
    }
}

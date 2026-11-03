import DesignSystem
import SwiftUI

/// The square glass panel of the You tab.
struct YouPanel<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    /// A light dark veil over the glass, under the content. A flat fill: no blur or offscreen pass, so the scroll
    /// costs the same.
    static var shade: Color { .black.opacity(0.08) }

    var body: some View {
        FrostedCard(radius: 0, padding: 0, pinsPhoto: true) {
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Self.shade)
        }
    }
}

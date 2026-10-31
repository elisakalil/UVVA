import DesignSystem
import SwiftUI

/// The square glass panel of the You tab.
struct YouPanel<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        FrostedCard(radius: 0, padding: 0, pinsPhoto: true) {
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
        }
    }
}

import DesignSystem
import SwiftUI

/// The lesson's page: the wine-stained paper of the Lessons artboard (note-bg) on its wine ground, as wide as the
/// screen and softened a touch.
struct LessonBackground: View {
    var body: some View {
        // An overlay, so the filled image never widens the player's layout.
        Color(hex: 0x4B1D2D)
            .overlay {
                Image("LessonBackground", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 1.2)
                    .opacity(0.92)
            }
            .clipped()
            .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

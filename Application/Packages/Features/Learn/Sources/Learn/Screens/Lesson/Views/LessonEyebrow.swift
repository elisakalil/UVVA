import DesignSystem
import SwiftUI

/// The small caps line above a title in the player ("Concept", "Choose one", "By the end you can").
struct LessonEyebrow: View {
    var text: String
    var color: Color = LessonPalette.dim

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(11))
            .tracking(1.8)
            .foregroundStyle(color)
    }
}

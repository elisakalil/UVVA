import DesignSystem
import SwiftUI

/// "Lesson complete +15 XP", over the top of the Summary for a moment (LEARN-R19).
struct LessonCompleteNote: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(10.5, .regular))
            .tracking(2.4)
            .foregroundStyle(LessonPalette.wine)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(LessonPalette.ink))
            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            .accessibilityAddTraits(.isStaticText)
    }
}

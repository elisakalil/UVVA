import DesignSystem
import SwiftUI

/// The small caps label over each part of the note: "YOUR NOTE", "AGAIN", "GRAPE".
struct NoteEyebrow: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8.5, .regular))
            .tracking(2.7)
            .foregroundStyle(NotePalette.ink.opacity(0.55))
    }
}

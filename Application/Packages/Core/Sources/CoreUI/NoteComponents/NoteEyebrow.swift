#if os(iOS)
import DesignSystem
import SwiftUI

/// The small caps label over each part of the note: "YOUR NOTE", "AGAIN", "GRAPE".
public struct NoteEyebrow: View {
    var text: String

    public init(text: String) { self.text = text }

    public var body: some View {
        Text(text.uppercased())
            .font(UVVAFont.sans(8.5, .regular))
            .tracking(2.7)
            .foregroundStyle(NotePalette.ink.opacity(0.55))
    }
}
#endif

#if os(iOS) && DEBUG
import DesignSystem
import SwiftUI

/// Debug builds only: what the label reading saw at each step (CELLAR-R17), folded under its title so it stays out
/// of the way. The text can be selected and copied.
struct NewNoteReadingDebugView: View {
    var text: String

    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.smooth(duration: 0.25)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 8) {
                    NoteEyebrow(text: "Label reading · debug")
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .opacity(0.55)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen {
                Text(text)
                    .font(.system(size: 11, design: .monospaced))
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(NotePalette.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
#endif

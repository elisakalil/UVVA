#if os(iOS) && DEBUG
import DesignSystem
import SwiftUI

/// Debug builds only: what the label reading saw at each step (CELLAR-R17), folded under its title so it stays out
/// of the way. The text can be selected and copied, and the reading exported as the camera gave it, to replay it in
/// a test (`LabelScanExport`).
struct NewNoteReadingDebugView: View {
    var text: String
    var export: String?

    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.smooth(duration: 0.25)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 8) {
                    NoteEyebrow(text: String(localized: "Label reading · debug", bundle: .module))
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .opacity(0.55)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen {
                if let export {
                    ShareLink(item: export, preview: SharePreview(String(localized: "Label scan", bundle: .module))) {
                        Label(String(localized: "Export scan", bundle: .module), systemImage: "square.and.arrow.up")
                            .font(.system(size: 12))
                            .frame(minHeight: 44)
                    }
                }
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

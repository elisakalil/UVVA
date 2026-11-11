import CoreUI
import Core
import DesignSystem
import SwiftUI

/// "Would you drink it again?" with Yes, No and Maybe, while editing (CELLAR-R27).
struct NoteVerdictPicker: View {
    var title: String
    var verdicts: [NoteVerdictUIModel]
    var onPick: (Verdict) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            NoteEyebrow(text: title)
            HStack(spacing: 8) {
                ForEach(verdicts) { option in
                    Button { onPick(option.verdict) } label: {
                        Text(option.label)
                            .font(UVVAFont.sans(12))
                            .foregroundStyle(option.isSelected ? UVVAColor.creamFill : NotePalette.ink.opacity(0.72))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background {
                                if option.isSelected {
                                    Capsule().fill(NotePalette.ink)
                                } else {
                                    Capsule().strokeBorder(NotePalette.ink.opacity(0.22), lineWidth: 0.5)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option.isSelected ? .isSelected : [])
                }
            }
        }
    }
}

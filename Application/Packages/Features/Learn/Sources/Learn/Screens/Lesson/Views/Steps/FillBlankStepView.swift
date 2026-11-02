import DesignSystem
import SwiftUI

/// fillBlank: the sentence with its blank, and the words to pick from.
struct FillBlankStepView: View {
    var model: FillBlankUIModel
    var onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                LessonEyebrow(text: String(localized: "Complete the sentence", bundle: .module))
                sentence
                    .font(UVVAFont.sans(26, .ultraLight))
                    .tracking(-0.6)
                    .lineSpacing(8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 28)

            VStack(alignment: .leading, spacing: 14) {
                LessonEyebrow(text: String(localized: "Pick a word", bundle: .module))
                FlowLayout(spacing: 8) {
                    ForEach(model.options) { option in word(option) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
        }
        .foregroundStyle(LessonPalette.ink)
    }

    /// The blank holds the word picked, underlined in its colour.
    private var sentence: Text {
        let tone = LessonPalette.tone(model.wordState)
        let blank = Text(model.word.map { " \($0) " } ?? "\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}")
            .foregroundStyle(tone)
            .underline(true, color: tone)
        return Text("\(model.before)\(blank)\(model.after)")
    }

    private func word(_ option: OptionUIModel) -> some View {
        let tone = LessonPalette.tone(option.state)
        let isMarked = option.state == .correct || option.state == .wrong
        return Button { onTap(option.label) } label: {
            Text(option.label)
                .font(UVVAFont.sans(14))
                .foregroundStyle(isMarked ? LessonPalette.wine : tone)
                .padding(.horizontal, 18)
                .frame(minHeight: 44)
                .background {
                    if isMarked {
                        Capsule().fill(tone)
                    } else {
                        Capsule().strokeBorder(option.state == .idle ? LessonPalette.ink.opacity(0.3) : tone, lineWidth: 1)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

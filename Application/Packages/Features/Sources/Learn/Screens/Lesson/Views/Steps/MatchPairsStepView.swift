import DesignSystem
import SwiftUI

/// matchPairs (LEARN-R18): a term on the left, then its match on the right.
struct MatchPairsStepView: View {
    var model: MatchPairsUIModel
    var onTapLeft: (Int) -> Void
    var onTapRight: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QuestionPrompt(prompt: model.prompt,
                           hint: String(localized: "Tap a term, then its match. Tap a matched term to undo.", bundle: .module))
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 8) { ForEach(model.left) { cell($0, action: onTapLeft) } }
                VStack(spacing: 8) { ForEach(model.right) { cell($0, action: onTapRight) } }
            }
            .padding(.horizontal, 16)
            Text(model.status)
                .font(UVVAFont.sans(14))
                .foregroundStyle(model.isMiss ? LessonPalette.wrong : LessonPalette.ink.opacity(0.72))
                .padding(.horizontal, 24)
                .padding(.top, 16)
        }
    }

    private func cell(_ term: OptionUIModel, action: @escaping (Int) -> Void) -> some View {
        let isPicked = term.state == .selected
        return Button { action(term.id) } label: {
            Text(term.label)
                .font(UVVAFont.sans(15))
                .foregroundStyle(isPicked ? LessonPalette.wine : LessonPalette.tone(term.state))
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(PairCell.background(term.state, pickedFill: LessonPalette.ink))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

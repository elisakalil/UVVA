import DesignSystem
import SwiftUI

/// ordering: tap one item, then the place it should go, to swap the two.
struct OrderingStepView: View {
    var model: OrderingUIModel
    var onTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QuestionPrompt(prompt: model.prompt, hint: model.hint)
            VStack(spacing: 8) {
                ForEach(model.rows) { row in item(row) }
            }
            .padding(.horizontal, 16)
        }
    }

    private func item(_ row: OptionUIModel) -> some View {
        let tone = LessonPalette.tone(row.state)
        let isPicked = row.state == .selected
        return Button { onTap(row.id) } label: {
            HStack(spacing: 12) {
                Text(row.number)
                    .font(UVVAFont.sans(12).monospacedDigit())
                    .foregroundStyle(isPicked ? LessonPalette.wine : row.state == .idle ? LessonPalette.dim : tone)
                    .frame(width: 22, alignment: .leading)
                Text(row.label)
                    .font(UVVAFont.sans(15))
                    .foregroundStyle(isPicked ? LessonPalette.wine : tone)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .background(PairCell.background(row.state, pickedFill: LessonPalette.ink))
            .offset(x: isPicked ? 6 : 0)
            .animation(.easeOut(duration: 0.18), value: row.state)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

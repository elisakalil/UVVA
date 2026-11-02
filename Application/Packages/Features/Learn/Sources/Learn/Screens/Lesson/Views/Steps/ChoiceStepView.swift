import DesignSystem
import SwiftUI

/// multipleChoice, selectMultiple and trueFalse. After "Check" the right option reads "Correct" and a wrong pick
/// "Your pick", in colour, without ticks or crosses (D7).
struct ChoiceStepView: View {
    var model: ChoiceUIModel
    var onTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QuestionPrompt(prompt: model.prompt)
            if model.kind == .trueFalse {
                HStack(spacing: 0) {
                    ForEach(model.options) { option in trueFalse(option) }
                }
            } else {
                ForEach(model.options) { option in row(option) }
            }
        }
    }

    private func row(_ option: OptionUIModel) -> some View {
        let tone = LessonPalette.tone(option.state)
        let isMarked = option.state == .correct || option.state == .wrong
        return Button { onTap(option.id) } label: {
            HStack(spacing: 16) {
                if model.kind == .multiple {
                    RoundedRectangle(cornerRadius: 1)
                        .strokeBorder(option.state == .idle ? LessonPalette.ink.opacity(0.42) : tone, lineWidth: 0.5)
                        .background(RoundedRectangle(cornerRadius: 1).fill(option.state == .idle ? .clear : tone))
                        .frame(width: 12, height: 12)
                } else {
                    Text(option.number)
                        .font(UVVAFont.sans(15).monospacedDigit())
                        .foregroundStyle(option.state == .idle ? LessonPalette.dim : tone)
                        .frame(minWidth: 20, alignment: .leading)
                }
                Text(option.label)
                    .font(UVVAFont.sans(16, isMarked ? .medium : .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isMarked, model.kind == .single {
                    Text(option.state == .correct ? String(localized: "Correct", bundle: .module).uppercased()
                                                  : String(localized: "Your pick", bundle: .module).uppercased())
                        .font(UVVAFont.sans(10))
                        .tracking(1.6)
                }
            }
            .foregroundStyle(tone)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(minHeight: 62)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(option.state == .selected ? .isSelected : [])
    }

    private func trueFalse(_ option: OptionUIModel) -> some View {
        let tone = LessonPalette.tone(option.state)
        return Button { onTap(option.id) } label: {
            VStack(alignment: .leading, spacing: 34) {
                Circle()
                    .fill(option.state == .idle ? .clear : tone)
                    .overlay(Circle().strokeBorder(option.state == .idle ? LessonPalette.ink.opacity(0.32) : .clear, lineWidth: 1))
                    .frame(width: 28, height: 28)
                Text(option.label).font(UVVAFont.sans(34, .ultraLight)).tracking(-1.2)
            }
            .foregroundStyle(tone)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 156, alignment: .topLeading)
            .background(option.state == .correct || option.state == .wrong ? LessonPalette.ink.opacity(0.045) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(option.state == .selected ? .isSelected : [])
    }
}

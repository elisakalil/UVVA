import DesignSystem
import SwiftUI

/// LEARN-R19: the toast, "Lesson complete" with the XP, the score and what was missed, what was learned,
/// and the lesson that comes next.
struct SummaryStepView: View {
    var model: LessonSummaryUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The word never breaks; its meaning goes under it when they do not fit side by side.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) { toast; caps(model.toastMeaning, size: 10).fixedSize() }
                VStack(alignment: .leading, spacing: 6) { toast; caps(model.toastMeaning, size: 10) }
            }
            Text(model.title)
                .font(UVVAFont.sans(34, .ultraLight))
                .tracking(-1)
                .padding(.top, 18)
            HStack(spacing: 14) {
                caps(String(localized: "Lesson complete", bundle: .module), size: 10)
                caps(model.xp, size: 10)
                caps(String(localized: "\(model.score) right", bundle: .module), size: 10)
            }
            .padding(.top, 14)

            if !model.missed.isEmpty {
                section(String(localized: "To look at again", bundle: .module), items: model.missed)
            }
            section(String(localized: "What you've learned", bundle: .module), items: model.points)

            caps(model.nextEyebrow, size: 10).padding(.top, 44)
            Text(model.nextTitle).font(UVVAFont.sans(18)).padding(.top, 8)
        }
        .foregroundStyle(LessonPalette.ink)
        .padding(.leading, 22)
        .padding(.trailing, 12)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toast: some View {
        Text(model.toast)
            .font(UVVAFont.redGrapes(44))
            .foregroundStyle(LessonPalette.accent)
            .lineLimit(1)
            .fixedSize()
    }

    private func caps(_ text: String, size: CGFloat) -> some View {
        Text(text.uppercased()).font(UVVAFont.sans(size)).tracking(2.4).foregroundStyle(LessonPalette.dim)
    }

    private func section(_ title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            caps(title, size: 10).padding(.bottom, 4)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(String(format: "%02d", index + 1))
                        .font(UVVAFont.sans(11).monospacedDigit())
                        .foregroundStyle(LessonPalette.dim)
                        .frame(width: 20, alignment: .leading)
                    Text(item).font(UVVAFont.sans(15)).lineSpacing(4)
                }
            }
        }
        .padding(.top, 44)
    }
}

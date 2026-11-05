import DesignSystem
import SwiftUI

/// LEARN-R19: the toast, what was learned, and the lesson that comes next. "Lesson complete" shows over it
/// as a note (`LessonCompleteNote`).
struct SummaryStepView: View {
    var resources = LearnResourcesUIModel()
    var model: LessonSummaryUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) { toast; meaning.fixedSize() }
                VStack(alignment: .leading, spacing: 8) { toast; meaning }
            }

            VStack(alignment: .leading, spacing: 22) {
                caps(resources.whatYouVeLearnedText)
                ForEach(Array(model.points.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(String(format: "%02d", index + 1))
                            .font(UVVAFont.sans(11).monospacedDigit())
                            .foregroundStyle(LessonPalette.dim)
                            .frame(width: 20, alignment: .leading)
                        Text(point).font(UVVAFont.sans(15)).lineSpacing(5)
                    }
                }
            }
            .padding(.top, 52)

            caps(model.nextEyebrow).padding(.top, 56)
            Text(model.nextTitle).font(UVVAFont.sans(18)).padding(.top, 10)
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

    private var meaning: some View {
        Text(model.toastMeaning.uppercased())
            .font(UVVAFont.sans(10))
            .tracking(2.4)
            .foregroundStyle(LessonPalette.accent)
    }

    private func caps(_ text: String) -> some View {
        Text(text.uppercased()).font(UVVAFont.sans(10)).tracking(2.4).foregroundStyle(LessonPalette.dim)
    }
}

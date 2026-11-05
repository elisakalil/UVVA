import DesignSystem
import SwiftUI

/// The cover (LEARN-R12): the lesson number and title, minutes, XP and steps, and "By the end you can".
struct LessonCoverView: View {
    var resources = LearnResourcesUIModel()
    var model: LessonCoverUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    LessonEyebrow(text: model.eyebrow)
                    Spacer()
                    Text(model.number)
                        .font(UVVAFont.redGrapes(60))
                        .foregroundStyle(LessonPalette.accent)
                }
                Text(model.title)
                    .font(UVVAFont.sans(44, .ultraLight))
                    .tracking(-1.5)
                Text(model.subtitle)
                    .font(UVVAFont.sans(15))
                    .foregroundStyle(LessonPalette.dim)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            HStack(spacing: 0) {
                stat(model.minutes, resources.minutesText, leading: false)
                stat(model.xp, resources.xpText, leading: true)
                stat(model.steps, resources.stepsText, leading: true)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .overlay(alignment: .top) { Rectangle().fill(LessonPalette.line).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(LessonPalette.line).frame(height: 1) }

            if !model.objectives.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    LessonEyebrow(text: resources.byTheEndYouCanText)
                    ForEach(Array(model.objectives.enumerated()), id: \.offset) { index, objective in
                        HStack(alignment: .firstTextBaseline, spacing: 14) {
                            Text(String(format: "%02d", index + 1))
                                .font(UVVAFont.sans(12))
                                .foregroundStyle(LessonPalette.dim)
                                .frame(width: 22, alignment: .leading)
                            Text(objective).font(UVVAFont.sans(15)).lineSpacing(4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 22)
            }
        }
        .foregroundStyle(LessonPalette.ink)
    }

    private func stat(_ value: String, _ label: String, leading: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(UVVAFont.sans(30, .ultraLight))
            Text(label.uppercased()).font(UVVAFont.sans(11)).tracking(1.8).foregroundStyle(LessonPalette.dim)
        }
        .padding(.leading, leading ? 14 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            if leading { Rectangle().fill(LessonPalette.line).frame(width: 1) }
        }
    }
}

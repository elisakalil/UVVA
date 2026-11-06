import DesignSystem
import SwiftUI

/// Lesson introduction: title, handwritten position, three metrics and numbered objectives.
struct LessonCoverView: View {
    var resources = LearnResourcesUIModel()
    var model: LessonCoverUIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.title)
                .font(UVVAFont.sans(38, .ultraLight))
                .tracking(-1.6)
                .fixedSize(horizontal: false, vertical: true)

            Text(model.position)
                .font(UVVAFont.redGrapes(15))
                .tracking(2)
                .lineSpacing(3)
                .foregroundStyle(LessonPalette.accent)
                .padding(.top, 22)
                .accessibilityLabel(model.position.replacingOccurrences(of: "\n", with: " "))

            HStack(spacing: 0) {
                stat(model.minutes, resources.minutesText, separated: false)
                stat(model.xp, resources.xpText, separated: true)
                stat(model.steps, resources.stepsText, separated: true)
            }
            .padding(.top, 34)

            if !model.objectives.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    LessonEyebrow(text: resources.byTheEndYouCanText)
                        .padding(.bottom, 2)
                    VStack(spacing: 0) {
                        ForEach(Array(model.objectives.enumerated()), id: \.offset) { index, objective in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(String(format: "%02d", index + 1))
                                    .font(UVVAFont.sans(10))
                                    .foregroundStyle(LessonPalette.dim)
                                    .frame(width: 22, alignment: .leading)
                                Text(objective)
                                    .font(UVVAFont.sans(14))
                                    .tracking(-0.4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 49, alignment: .leading)
                            .padding(.vertical, 1)
                            .overlay(alignment: .bottom) {
                                if index < model.objectives.count - 1 {
                                    Rectangle().fill(LessonPalette.line).frame(height: 0.5)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 72)
            }
        }
        .padding(.horizontal, 30)
        .foregroundStyle(LessonPalette.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stat(_ value: String, _ label: String, separated: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(UVVAFont.sans(38, .ultraLight))
            Text(label.uppercased())
                .font(UVVAFont.sans(10))
                .tracking(1.8)
                .foregroundStyle(LessonPalette.dim)
        }
        .padding(.leading, separated ? 16 : 0)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .overlay(alignment: .leading) {
            if separated { Rectangle().fill(LessonPalette.line).frame(width: 0.5) }
        }
    }
}

import DesignSystem
import SwiftUI

/// "‹  Lesson 3 | TITLE", and under it the step dots and "03 / 06".
struct LessonTopBar: View {
    var model: StepHeaderUIModel
    var ink: Color
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .light))
                        .frame(width: 32, height: 40, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(model.backLeaves ? Text("Leave the lesson", bundle: .module)
                                                     : Text("Previous screen", bundle: .module))
                Text(model.brand)
                    .font(model.current == nil ? UVVAFont.whiteGrape(15) : UVVAFont.redGrapes(15))
                    .tracking(model.current == nil ? 2 : 0.6)
                Rectangle().fill(ink.opacity(0.35)).frame(width: 1, height: 11)
                Text(model.title.uppercased())
                    .font(UVVAFont.sans(9))
                    .tracking(2.5)
                    .lineLimit(1)
                    .opacity(0.7)
                Spacer(minLength: 0)
            }
            if let current = model.current {
                HStack(spacing: 14) {
                    StepDots(current: current, total: model.total, ink: ink)
                    Text(model.counter)
                        .font(UVVAFont.sans(9).monospacedDigit())
                        .tracking(2.7)
                        .opacity(0.8)
                }
            }
        }
        .foregroundStyle(ink)
    }
}

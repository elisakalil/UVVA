import DesignSystem
import SwiftUI

/// One of the three steps of "How UVVA works".
struct QuizIntroStepRow: View {
    var step: QuizIntroStepUIModel

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(step.number)
                .font(UVVAFont.sans(18, .ultraLight))
                .frame(width: 30, alignment: .leading)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                Text(step.title).font(UVVAFont.sans(14))
                Text(step.body)
                    .font(UVVAFont.sans(11.5))
                    .lineSpacing(4)
                    .opacity(0.84)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 11)
    }
}

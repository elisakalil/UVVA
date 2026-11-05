import DesignSystem
import SwiftUI

/// An axis with its level as ten pips and its word (QUIZ-R05, R16). The top three are brighter.
struct QuizReadingRow: View {
    var row: QuizReadingRowUIModel

    var body: some View {
        HStack(spacing: 14) {
            Text(row.name.uppercased())
                .font(UVVAFont.sans(12))
                .tracking(1.9)
                .opacity(row.isStrong ? 1 : 0.62)
                .frame(width: 96, alignment: .leading)
            HStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { index in
                    if index < row.level {
                        Circle().opacity(row.isStrong ? 0.92 : 0.7).frame(width: 4, height: 4)
                    } else {
                        Circle().strokeBorder(lineWidth: 0.5).opacity(0.3).frame(width: 4, height: 4)
                    }
                }
            }
            Text(row.word)
                .font(UVVAFont.sans(11))
                .tracking(1.1)
                .opacity(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }
}

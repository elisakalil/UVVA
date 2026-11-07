import DesignSystem
import SwiftUI

/// An axis with ten pips, lit up to its position on the Quiz bar, and its word (QUIZ-R05, R16).
struct ReadingLine: View {
    var row: MapReadingRow

    var body: some View {
        HStack(spacing: 14) {
            Text(row.name.uppercased())
                .font(UVVAFont.sans(11.5, .regular))
                .tracking(1.8)
                .opacity(row.isStrong ? 1 : 0.62)
                .frame(width: 92, alignment: .leading)
            HStack(spacing: 5) {
                ForEach(0..<10, id: \.self) { index in
                    if index <= row.level {
                        Circle().opacity(row.isStrong ? 0.92 : 0.7).frame(width: 4, height: 4)
                    } else {
                        Circle().strokeBorder(lineWidth: 0.5).opacity(0.3).frame(width: 4, height: 4)
                    }
                }
            }
            Text(row.word)
                .font(UVVAFont.sans(10.5))
                .tracking(1)
                .opacity(0.82)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

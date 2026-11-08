import SwiftUI

/// An axis with ten pips, lit up to its position on the Quiz bar, and its word (QUIZ-R05, R16).
/// Used by You › Map and by a friend's palate (FRI-R11).
public struct PalateReadingLine: View {
    var name: String
    var level: Int
    var word: String
    var isStrong: Bool

    public init(name: String, level: Int, word: String, isStrong: Bool) {
        self.name = name
        self.level = level
        self.word = word
        self.isStrong = isStrong
    }

    public var body: some View {
        HStack(spacing: 14) {
            Text(name.uppercased())
                .font(UVVAFont.sans(11.5, .regular))
                .tracking(1.8)
                .opacity(isStrong ? 1 : 0.62)
                .frame(width: 92, alignment: .leading)
            HStack(spacing: 5) {
                ForEach(0..<10, id: \.self) { index in
                    if index <= level {
                        Circle().opacity(isStrong ? 0.92 : 0.7).frame(width: 4, height: 4)
                    } else {
                        Circle().strokeBorder(lineWidth: 0.5).opacity(0.3).frame(width: 4, height: 4)
                    }
                }
            }
            Text(word)
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

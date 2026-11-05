import SwiftUI

/// Eight hairlines: the readings done, the one on screen, the ones to come (QUIZ-R07).
struct ReadingProgress: View {
    var resources = QuizResourcesUIModel()
    var count: Int
    var current: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                Rectangle()
                    .opacity(index < current ? 0.6 : index == current ? 0.35 : 0.12)
                    .frame(height: 1)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(resources.readingAccessibility(current: current, count: count)))
    }
}

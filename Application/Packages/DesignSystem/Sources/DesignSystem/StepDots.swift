import SwiftUI

/// One dot per step, joined by a hairline: the steps passed filled, the current one glowing. The progress of a
/// lesson (LEARN-R13) and of the Quiz readings (QUIZ-R07).
public struct StepDots: View {
    var current: Int
    var total: Int
    var ink: Color
    var accessibilityLabel: String

    public init(current: Int, total: Int, ink: Color, accessibilityLabel: String) {
        self.current = current
        self.total = total
        self.ink = ink
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<total, id: \.self) { index in
                dot(index)
                if index < total - 1 {
                    Rectangle()
                        .fill(ink.opacity(index < current ? 0.85 : 0.28))
                        .frame(minWidth: 4, maxWidth: .infinity)
                        .frame(height: 1)
                }
            }
        }
        .frame(height: 14)
        .animation(.spring(duration: 0.45, bounce: 0.2), value: current)
        .accessibilityElement()
        .accessibilityLabel(Text(accessibilityLabel))
    }

    @ViewBuilder private func dot(_ index: Int) -> some View {
        if index == current {
            Circle().fill(UVVAColor.grape).frame(width: 7, height: 7)
                .shadow(color: UVVAColor.grape.opacity(0.75), radius: 4)
        } else if index < current {
            Circle().fill(ink).frame(width: 6, height: 6)
        } else {
            Circle().strokeBorder(ink.opacity(0.5), lineWidth: 1).frame(width: 6, height: 6)
        }
    }
}

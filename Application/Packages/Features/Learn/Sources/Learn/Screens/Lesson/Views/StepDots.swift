import SwiftUI

/// One dot per step, joined by a hairline: the steps passed filled, the current one glowing (LEARN-R13).
struct StepDots: View {
    var current: Int
    var total: Int
    var ink: Color

    var body: some View {
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
        .accessibilityElement()
        .accessibilityLabel(Text("Step \(current + 1) of \(total)", bundle: .module))
    }

    @ViewBuilder private func dot(_ index: Int) -> some View {
        if index == current {
            Circle().fill(LessonPalette.accent).frame(width: 7, height: 7)
                .shadow(color: LessonPalette.accent.opacity(0.75), radius: 4)
        } else if index < current {
            Circle().fill(ink).frame(width: 6, height: 6)
        } else {
            Circle().strokeBorder(ink.opacity(0.5), lineWidth: 1).frame(width: 6, height: 6)
        }
    }
}

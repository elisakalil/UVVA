import Core
import DesignSystem
import SwiftUI

/// The dot before a course: an outline not started, filled when done, breathing while in progress (LEARN-R10a).
struct StateDot: View {
    var state: CourseState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(state == .done ? UVVAColor.creamFill.opacity(0.85) : .clear)
            .overlay(Circle().strokeBorder(UVVAColor.creamFill.opacity(0.75), lineWidth: 1))
            .frame(width: 7, height: 7)
            .background {
                if state == .inProgress, !reduceMotion {
                    Circle()
                        .fill(UVVAColor.creamFill.opacity(0.5))
                        .phaseAnimator([false, true]) { circle, grown in
                            circle.scaleEffect(grown ? 2.6 : 1).opacity(grown ? 0 : 0.8)
                        } animation: { grown in grown ? .easeOut(duration: 2.6) : .linear(duration: 0) }
                }
            }
            .accessibilityHidden(true)
    }
}

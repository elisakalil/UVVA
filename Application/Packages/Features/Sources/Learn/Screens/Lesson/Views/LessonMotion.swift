import SwiftUI

/// The small movements of the lesson, each one quiet and each one dropped under Reduce Motion.
extension View {
    /// A right answer breathes once, from its leading edge, when it turns right.
    func lessonBreath(_ isOn: Bool) -> some View { modifier(LessonBreath(isOn: isOn)) }

    /// A term that is not a pair leans aside a few points and settles: a nudge, never a shake.
    func lessonNudge(_ isOn: Bool) -> some View { modifier(LessonNudge(isOn: isOn)) }

    /// Rises a little into place, after `delay`, when it first appears.
    func lessonRise(_ isShown: Bool, delay: Double = 0) -> some View { modifier(LessonRise(isShown: isShown, delay: delay)) }
}

private struct LessonBreath: ViewModifier {
    var isOn: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: 1.0, trigger: isOn) { view, scale in
                view.scaleEffect(scale, anchor: .leading)
            } keyframes: { _ in
                CubicKeyframe(isOn ? 1.02 : 1, duration: 0.18)
                SpringKeyframe(1, duration: 0.45, spring: .smooth)
            }
        }
    }
}

private struct LessonNudge: ViewModifier {
    var isOn: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: 0.0, trigger: isOn) { view, x in
                view.offset(x: x)
            } keyframes: { _ in
                CubicKeyframe(isOn ? 3 : 0, duration: 0.09)
                SpringKeyframe(0, duration: 0.35, spring: .snappy)
            }
        }
    }
}

private struct LessonRise: ViewModifier {
    var isShown: Bool
    var delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : 8)
            .animation(.easeOut(duration: 0.32).delay(delay), value: isShown)
    }
}

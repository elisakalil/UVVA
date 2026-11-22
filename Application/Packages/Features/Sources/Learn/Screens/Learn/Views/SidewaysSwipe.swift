import SwiftUI
import UIKit

/// A sideways pan that only starts when the finger moves more sideways than up or down. A vertical drag fails it at
/// once, so the scroll view around it starts scrolling straight away (a SwiftUI DragGesture inside a ScrollView
/// holds the scroll back for a moment).
struct SidewaysSwipe: UIGestureRecognizerRepresentable {
    /// The sideways distance so far.
    var onChanged: (CGFloat) -> Void
    /// The sideways distance and speed when the finger lifts; zero for both when the pan is cancelled.
    var onEnded: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let translation = recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed: onChanged(translation)
        case .ended: onEnded(translation, recognizer.velocity(in: recognizer.view).x)
        case .cancelled, .failed: onEnded(0, 0)
        default: break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y) * 1.2
        }

        /// Never holds back the scroll view, the filter row or the map's taps.
        func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

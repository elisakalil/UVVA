import Core
import Foundation

/// The Home tour as a pure state machine (HOME-R29 to R33). Step 0 is the intro; 1...6 are the steps.
public struct GuidedTour: Equatable, Sendable {
    public static let stepCount = 6
    public static let tourID = "home"

    public private(set) var step = 0
    public private(set) var isFinished = false

    public init() {}

    /// HOME-R29: once per account, after the first map only.
    public static func shouldShow(quizExit: QuizExit?, seenTours: Set<String>) -> Bool {
        quizExit == .homeWithTour && !seenTours.contains(tourID)
    }

    /// "Show me", "Next", and "Start" on the last step (HOME-R32, R33).
    public mutating func next() {
        if step == Self.stepCount { isFinished = true } else { step += 1 }
    }

    /// `‹`: from step 1 back to the intro.
    public mutating func back() {
        guard step > 0 else { return }
        step -= 1
    }

    /// A progress dot.
    public mutating func pick(_ step: Int) {
        guard (1...Self.stepCount).contains(step) else { return }
        self.step = step
    }
}

import Core
import Foundation

/// The Quiz as a pure state machine: the step, the answer and the question version of each axis (QUIZ-R07 to R13, R18).
/// Answers live only here, in memory: nothing is kept until "Keep this map" (QUIZ-R13a).
struct QuizFlow: Equatable, Sendable {
    /// The order of the questions (QUIZ-R01).
    static let order: [PalateAxis] = [.sweetness, .acidity, .tannin, .body, .fruit, .floral, .oak, .spice]
    static let versionCount = 3
    static let positions = 0...9

    private(set) var step: QuizStep = .intro
    private(set) var answers: [PalateAxis: Int] = [:]
    private(set) var versions: [PalateAxis: Int] = [:]

    /// The axis of the reading on screen.
    var axis: PalateAxis? {
        guard case let .reading(index) = step else { return nil }
        return Self.order[index]
    }

    /// 1...3; every axis starts on version 1 (QUIZ-R08).
    func version(of axis: PalateAxis) -> Int { versions[axis] ?? 1 }

    /// The position chosen on the reading on screen; nil while the bar is empty (QUIZ-R10).
    var selection: Int? { axis.flatMap { answers[$0] } }

    /// QUIZ-R11
    var canAdvance: Bool { selection != nil }

    var isLastReading: Bool { step == .reading(Self.order.count - 1) }

    /// The map drawn from the answers, once all eight are given (QUIZ-R04).
    var map: PalateMap? {
        guard answers.count == Self.order.count else { return nil }
        return PalateMap(answers.mapValues(Double.init))
    }

    /// "Read my palate" (QUIZ-R06).
    mutating func start() {
        guard step == .intro else { return }
        step = .reading(0)
    }

    /// QUIZ-R10
    mutating func select(_ position: Int) {
        guard let axis, Self.positions.contains(position) else { return }
        answers[axis] = position
    }

    /// QUIZ-R09: the next version in a loop; the position stays.
    mutating func changeQuestion() {
        guard let axis else { return }
        versions[axis] = version(of: axis) % Self.versionCount + 1
    }

    /// "Next" and "Draw the map" (QUIZ-R11).
    mutating func next() {
        guard case let .reading(index) = step, canAdvance else { return }
        step = index == Self.order.count - 1 ? .result : .reading(index + 1)
    }

    /// `‹` (QUIZ-R12): one reading back with its answer kept; from the first reading to the Intro;
    /// from the map to the last reading.
    mutating func back() {
        switch step {
        case .intro: break
        case .reading(0): step = .intro
        case let .reading(index): step = .reading(index - 1)
        case .result: step = .reading(Self.order.count - 1)
        }
    }

    /// "Read it again" (QUIZ-R18): every bar empty, back to the first reading.
    mutating func readAgain() {
        answers = [:]
        versions = [:]
        step = .reading(0)
    }
}

import Core
import Foundation

/// Checking a question step (LEARN-R17, R18). Pure, so every rule is tested without the player.
enum LessonGrader {
    /// LEARN-R17: when "Check" is active. matchPairs has no Check.
    static func canCheck(_ step: LessonStep, _ draft: StepDraft) -> Bool {
        switch step {
        case .multipleChoice, .selectMultiple, .trueFalse: !draft.selection.isEmpty
        case .fillBlank: draft.word != nil
        case .ordering: true
        case .concept, .tip, .matchPairs, .summary: false
        }
    }

    /// What is kept of a checked step (LEARN-R14).
    static func answer(_ step: LessonStep, _ draft: StepDraft) -> LessonAnswer? {
        switch step {
        case .multipleChoice, .selectMultiple: .options(draft.selection)
        case .trueFalse: draft.selection.first.map { .trueFalse($0 == 0) }
        case let .fillBlank(_, options, _, _, canonical):
            draft.word.map { .word(option($0, from: options, to: canonical)) }
        case .ordering: .order(draft.order)
        case .matchPairs: .pairs(misses: draft.misses)
        case .concept, .tip, .summary: nil
        }
    }

    static func isCorrect(_ step: LessonStep, _ answer: LessonAnswer) -> Bool {
        switch (step, answer) {
        case let (.multipleChoice(_, _, right, _), .options(picked)): picked == [right]
        // Exactly the right set: missing one or adding one is wrong.
        case let (.selectMultiple(_, _, right, _), .options(picked)): picked == right
        case let (.trueFalse(_, right, _), .trueFalse(picked)): picked == right
        case let (.fillBlank(_, _, right, _, _), .word(picked)): displayedWord(picked, on: step) == right
        case let (.ordering(_, items, _), .order(order)): order == Array(items.indices)
        case let (.matchPairs, .pairs(misses)): misses == 0
        default: false
        }
    }

    /// Fill-in answers use the original word on disk so older versions can still read them.
    static func displayedWord(_ stored: String, on step: LessonStep) -> String {
        guard case let .fillBlank(_, options, _, _, canonical?) = step else { return stored }
        return option(stored, from: canonical, to: options)
    }

    private static func option(_ word: String, from source: [String], to target: [String]?) -> String {
        guard let target, let index = source.firstIndex(of: word), target.indices.contains(index) else { return word }
        return target[index]
    }

    /// LEARN-R17, R17a, R18: the explanation under "Correct" or "Not quite".
    static func explanation(_ step: LessonStep, _ answer: LessonAnswer) -> String {
        switch (step, answer) {
        case let (.multipleChoice(_, _, _, text), _), let (.selectMultiple(_, _, _, text), _),
             let (.trueFalse(_, _, text), _), let (.fillBlank(_, _, _, text, _), _):
            return text
        case let (.ordering(_, items, text), _):
            guard !isCorrect(step, answer) else { return text }
            let order = items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "  ")
            return String(localized: "Correct order: \(order)", bundle: .module) + (text.isEmpty ? "" : ". \(text)")
        case let (.matchPairs(_, pairs, text), .pairs(misses)):
            let tally = switch misses {
            case 0: String(localized: "All \(pairs.count) pairs matched on the first try.", bundle: .module)
            case 1: String(localized: "All \(pairs.count) pairs matched, with 1 wrong try.", bundle: .module)
            default: String(localized: "All \(pairs.count) pairs matched, with \(misses) wrong tries.", bundle: .module)
            }
            // The tally first (LEARN-R18), then the lesson's own explanation when it has one.
            guard let text, !text.isEmpty else { return tally }
            return "\(tally) \(text)"
        default:
            return ""
        }
    }
}

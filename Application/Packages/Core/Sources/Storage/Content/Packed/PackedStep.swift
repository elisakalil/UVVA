import Core
import Foundation

/// One step of a lesson as stored in `LessonEntity.stepsData` (LESSON.md §9). `answer` is an index for
/// multipleChoice, a boolean for trueFalse and a word for fillBlank, so it stays a `JSONValue` until the type is known.
struct PackedStep: Decodable {
    var type: String
    var title: String?
    var body: String?
    var highlight: String?
    var prompt: String?
    var options: [String]?
    var answer: JSONValue?
    var answers: [Int]?
    var items: [String]?
    var pairs: [PackedPair]?
    var explanation: String?
    var points: [String]?

    struct PackedPair: Decodable {
        var left: String
        var right: String
    }

    /// Nil for a type the app does not know, so a newer step type never breaks a lesson.
    var step: LessonStep? {
        let prompt = prompt ?? ""
        let explanation = explanation ?? ""
        switch (type, answer) {
        case ("concept", _):
            return .concept(title: title ?? "", body: body ?? "", highlight: highlight)
        case ("tip", _):
            return .tip(body: body ?? "")
        case let ("multipleChoice", .number(index)?):
            return .multipleChoice(prompt: prompt, options: options ?? [], answer: Int(index), explanation: explanation)
        case ("selectMultiple", _):
            return .selectMultiple(prompt: prompt, options: options ?? [], answers: Set(answers ?? []), explanation: explanation)
        case let ("trueFalse", .bool(value)?):
            return .trueFalse(prompt: prompt, answer: value, explanation: explanation)
        case let ("fillBlank", .string(word)?):
            return .fillBlank(prompt: prompt, options: options ?? [], answer: word, explanation: explanation)
        case ("ordering", _):
            return .ordering(prompt: prompt, items: items ?? [], explanation: explanation)
        case ("matchPairs", _):
            return .matchPairs(prompt: prompt, pairs: (pairs ?? []).map { MatchPair(left: $0.left, right: $0.right) },
                               explanation: self.explanation)
        case ("summary", _):
            return .summary(title: title ?? "", points: points ?? [])
        default:
            return nil
        }
    }
}

import Foundation

/// One reading (QUIZ-R07 to R13).
struct QuizReadingUIModel: Equatable {
    /// 0...7
    var index: Int
    var count: Int
    /// "3 of 8"
    var counter: String
    /// "Reading 3 · Tannin"
    var title: String
    var prompt: String
    /// The answer for the chosen position; nil while the bar is empty.
    var answer: String?
    var axisName: String
    var selection: Int?
    var button: String
    var canAdvance: Bool
    var footnote: String
}

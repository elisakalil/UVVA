import Foundation

/// "How UVVA works" (QUIZ-R06).
struct QuizIntroUIModel: Equatable {
    var greeting: String
    var title: String
    var body: String
    var steps: [QuizIntroStepUIModel]
    var length: String
    var button: String
    /// Only when redoing the map: a way out without changing it (QUIZ-R26).
    var canLeave: Bool
}

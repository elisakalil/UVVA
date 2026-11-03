import Foundation

/// "Correct" or "Not quite", and the explanation (LEARN-R17).
struct FeedbackUIModel: Equatable {
    var isCorrect: Bool
    var title: String
    var text: String
}

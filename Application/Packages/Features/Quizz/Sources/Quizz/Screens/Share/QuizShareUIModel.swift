import Core
import Foundation

/// The share sheet and its card (QUIZ-R19, R20).
struct QuizShareUIModel: Equatable {
    var heading: String
    var dominantPhrase: String
    var map: PalateMap
    var top3: [PalateAxis]
    var loves: String
    var never: String
    /// The text sent with the image on WhatsApp.
    var message: String
}

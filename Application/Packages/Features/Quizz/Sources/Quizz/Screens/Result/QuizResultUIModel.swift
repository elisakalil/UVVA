import Core
import Foundation

/// The map (QUIZ-R14 to R18).
struct QuizResultUIModel: Equatable {
    var dominantPhrase: String
    var map: PalateMap
    var top3: [PalateAxis]
    var caption: String
    var readings: [QuizReadingRowUIModel]
    var narrative: String
    var isSaving: Bool
    var failedToSave: Bool
}

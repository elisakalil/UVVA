import Core
import Foundation

/// The map (QUIZ-R14 to R18).
struct QuizResultUIModel: Equatable {
    var dominantPhrase: String
    var map: PalateMap
    /// The axes drawn strong on the chart (QUIZ-R16).
    var highlighted: [PalateAxis]
    var caption: String
    var readings: [QuizReadingRowUIModel]
    var narrative: String
    var isSaving: Bool
    var failedToSave: Bool
}

import Core
import Foundation

struct QuizResultUIModel: Equatable {
    var dominantPhrase: String
    var map: PalateMap
    var highlighted: [PalateAxis]
    var caption: String
    var readings: [QuizReadingRowUIModel]
    var narrative: String
    var isSaving: Bool
    var failedToSave: Bool
}

import Foundation

struct NoteResourcesUIModel {
    var tastingNoteText = String(localized: "Tasting note", bundle: .module)
    var editNoteText = String(localized: "Edit note", bundle: .module)
    var backText = String(localized: "Back", bundle: .module)
    var againText = String(localized: "Again", bundle: .module)
    var yourNoteText = String(localized: "Your note", bundle: .module)
    var notePromptText = String(localized: "Kept for you only", bundle: .module)
    var readingText = String(localized: "UVVA’s reading", bundle: .module)
    var drinkAgainText = String(localized: "Would you drink it again?", bundle: .module)
    var editText = String(localized: "Edit", bundle: .module)
    var deleteText = String(localized: "Delete", bundle: .module)
    var cancelText = String(localized: "Cancel", bundle: .module)
    var saveChangesText = String(localized: "Save changes", bundle: .module)
    var deleteTitleText = String(localized: "Delete this note?", bundle: .module)
    var deleteBodyText = String(localized: "It leaves your cellar and stops counting towards your palate map. This can’t be undone.", bundle: .module)
    var saveErrorText = String(localized: "Your changes weren’t saved. Try again.", bundle: .module)
    var deleteErrorText = String(localized: "The note wasn’t deleted. Try again.", bundle: .module)
    var grapeText = String(localized: "Grape", bundle: .module)
    var regionText = String(localized: "Region", bundle: .module)
    var vintageText = String(localized: "Vintage", bundle: .module)
    var typeText = String(localized: "Type", bundle: .module)
    var alcoholText = String(localized: "Alcohol", bundle: .module)
    var producerText = String(localized: "Producer", bundle: .module)
    var bodyText = String(localized: "Body", bundle: .module)
    var tanninText = String(localized: "Tannin", bundle: .module)
    var acidityText = String(localized: "Acidity", bundle: .module)
    var sweetnessText = String(localized: "Sweetness", bundle: .module)
    var backIcon = "chevron.left"

    func verdict(_ verdict: CellarTag) -> String { CellarResourcesUIModel().tag(verdict) }

    /// The word beside each line of the structure, on the 0–9 palate scale.
    func level(_ value: Double, of row: NoteStructureRow) -> String {
        switch row {
        case .body:
            value < 3.5 ? String(localized: "Light", bundle: .module)
                : value < 6.5 ? String(localized: "Medium", bundle: .module) : String(localized: "Full", bundle: .module)
        case .tannin, .acidity:
            value < 3.5 ? String(localized: "Low", bundle: .module)
                : value < 6.5 ? String(localized: "Medium", bundle: .module) : String(localized: "High", bundle: .module)
        case .sweetness:
            value < 2.5 ? String(localized: "Dry", bundle: .module)
                : value < 4.5 ? String(localized: "Off-dry", bundle: .module)
                : value < 6.5 ? String(localized: "Medium", bundle: .module) : String(localized: "Sweet", bundle: .module)
        }
    }

    func label(_ row: NoteStructureRow) -> String {
        switch row {
        case .body: bodyText
        case .tannin: tanninText
        case .acidity: acidityText
        case .sweetness: sweetnessText
        }
    }
}

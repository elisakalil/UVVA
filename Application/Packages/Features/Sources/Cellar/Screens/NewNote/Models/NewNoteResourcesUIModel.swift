import Foundation

struct NewNoteResourcesUIModel {
    var newNoteText = String(localized: "New note", bundle: .module)
    var closeText = String(localized: "Close", bundle: .module)
    var backText = String(localized: "Back", bundle: .module)

    // MARK: Photos (CELLAR-R16, R17)
    var frontTitleText = String(localized: "Photograph the front", bundle: .module)
    var frontBodyText = String(localized: "Fit the whole label inside the frame.", bundle: .module)
    var backTitleText = String(localized: "Now the back label", bundle: .module)
    var backBodyText = String(localized: "Grape, alcohol and producer are usually here.", bundle: .module)
    var readingTitleText = String(localized: "Reading your label", bundle: .module)
    var readingBodyText = String(localized: "This takes a few seconds.", bundle: .module)
    var readingProgressText = String(localized: "Reading grape, region, vintage", bundle: .module)
    var frontStepText = String(localized: "Front", bundle: .module)
    var backStepText = String(localized: "Back label", bundle: .module)
    var shutterText = String(localized: "Take photo", bundle: .module)
    var cameraUnavailableText = String(localized: "No camera on this device", bundle: .module)

    // MARK: Messages (CELLAR-R21, R22)
    var errorTitleText = String(localized: "We couldn’t read your label", bundle: .module)
    var errorBodyText = String(localized: "Check these two things and try again.", bundle: .module)
    var lightTitleText = String(localized: "Light", bundle: .module)
    var lightBodyText = String(localized: "Move somewhere brighter and keep the label out of shadow.", bundle: .module)
    var wholeLabelTitleText = String(localized: "Whole label", bundle: .module)
    var wholeLabelBodyText = String(localized: "Fit the whole label inside the frame, flat and in focus.", bundle: .module)
    var tryAgainText = String(localized: "Try again", bundle: .module)
    var fillInByHandText = String(localized: "Fill in by hand", bundle: .module)
    var deniedTitleText = String(localized: "The camera is off", bundle: .module)
    var deniedBodyText = String(localized: "UVVA needs the camera to read labels. Turn it on in Settings, or add the wine by hand.", bundle: .module)
    var openSettingsText = String(localized: "Open Settings", bundle: .module)

    // MARK: By hand (CELLAR-R23)
    var manualBodyText = String(localized: "Add what you can read on the label. Only the name is needed.", bundle: .module)
    var wineFieldText = String(localized: "Wine", bundle: .module)
    var producerFieldText = String(localized: "Producer", bundle: .module)
    var regionFieldText = String(localized: "Region", bundle: .module)
    var regionPromptText = String(localized: "Region or appellation", bundle: .module)
    var vintageFieldText = String(localized: "Vintage", bundle: .module)
    var grapeFieldText = String(localized: "Grape", bundle: .module)
    var grapePromptText = String(localized: "Grape or blend", bundle: .module)
    var typeFieldText = String(localized: "Type", bundle: .module)
    var continueText = String(localized: "Continue", bundle: .module)
    var manualErrorText = String(localized: "UVVA couldn’t read this wine. Try again.", bundle: .module)

    // MARK: The note (CELLAR-R18 to R20)
    var tastedQuestionText = String(localized: "Have you had this wine?", bundle: .module)
    var tastedYesText = String(localized: "Yes · would you drink it again", bundle: .module)
    var notYetText = String(localized: "Not yet · add to cellar or find it", bundle: .module)
    var requiredText = String(localized: "Required", bundle: .module)
    var addToCellarText = String(localized: "Add to cellar", bundle: .module)
    var findItText = String(localized: "Find it", bundle: .module)
    var redoText = String(localized: "Redo", bundle: .module)
    var saveNoteText = String(localized: "Save note", bundle: .module)
    var saveErrorText = String(localized: "The note wasn’t saved. Try again.", bundle: .module)

    // MARK: Discard (CELLAR-R25)
    var discardTitleText = String(localized: "Discard this note?", bundle: .module)
    var discardBodyText = String(localized: "Your photos and UVVA’s reading won’t be saved.", bundle: .module)
    var discardText = String(localized: "Discard", bundle: .module)
    var keepEditingText = String(localized: "Keep editing", bundle: .module)

    var closeIcon = "xmark"
    var backIcon = "chevron.left"

    /// The types of the catalog, in the artboard's order.
    static let types = ["Red", "White", "Rosé", "Sparkling", "Fortified"]

    func type(_ type: String) -> String {
        switch type {
        case "Red": String(localized: "Red", bundle: .module)
        case "White": String(localized: "White", bundle: .module)
        case "Rosé": String(localized: "Rosé", bundle: .module)
        case "Sparkling": String(localized: "Sparkling", bundle: .module)
        case "Fortified": String(localized: "Fortified", bundle: .module)
        default: type
        }
    }
}

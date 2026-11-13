import Foundation

struct NewNoteResourcesUIModel {
    /// The words of the wine on paper, shared with the saved note.
    var paper = NotePaperResources()
    var closeText = String(localized: "Close", bundle: .module)

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
    var libraryText = String(localized: "Choose from library", bundle: .module)
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
    var intensityInfoText = String(localized: "About intensity", bundle: .module)
    var intensityInfoParagraphs = [
        String(localized: "UVVA read this wine and set how strong it is on each axis of the map, from barely there to as much as it gets.", bundle: .module),
        String(localized: "Tasted it differently? Tap or slide a line to give your own reading. It's kept with your note, and the map of this wine follows it.", bundle: .module)
    ]
    var addText = String(localized: "Add", bundle: .module)
    var writeOptionText = String(localized: "Write your own", bundle: .module)
    var selectOptionText = String(localized: "Choose from the list", bundle: .module)
    var noOptionsText = String(localized: "No matching suggestions", bundle: .module)
    var tastedQuestionText = String(localized: "Have you had this wine?", bundle: .module)
    var rateAgainQuestionText = String(localized: "Rate it again?", bundle: .module)
    var yesText = String(localized: "Yes", bundle: .module)
    var noText = String(localized: "No", bundle: .module)
    var maybeText = String(localized: "Maybe", bundle: .module)
    var notePromptText = String(localized: "What stood out in the glass?", bundle: .module)
    var drinkAgainText = String(localized: "Would you drink it again?", bundle: .module)
    var notYetText = String(localized: "Not yet", bundle: .module)
    var addPhotoText = String(localized: "Add photo", bundle: .module)
    var changePhotoText = String(localized: "Change photo", bundle: .module)
    var photoTitleText = String(localized: "Photograph the wine", bundle: .module)
    var photoBodyText = String(localized: "The label, or the bottle as you remember it.", bundle: .module)
    var verdictRequiredText = String(localized: "Choose whether you would drink it again.", bundle: .module)
    var saveNoteText = String(localized: "Save note", bundle: .module)
    var saveErrorText = String(localized: "The note wasn’t saved. Try again.", bundle: .module)

    var closeIcon = "xmark"
    var libraryIcon = "photo.on.rectangle"
    var addPhotoIcon = "plus"

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

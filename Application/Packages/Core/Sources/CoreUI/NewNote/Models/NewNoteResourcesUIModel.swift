import Core
import Foundation

struct NewNoteResourcesUIModel {
    /// The words of the wine on paper, shared with the saved note.
    var paper = NotePaperResources()
    /// The rating under the photos and its sheet.
    var rating = NoteRatingResources()

    // MARK: Photos (CELLAR-R16, R17): a word or two, the motion says the rest
    var frontTitleText = String(localized: "Front label", bundle: .module)
    var backTitleText = String(localized: "Now the back", bundle: .module)
    /// Inside the frame before the back label is recorded.
    var backHintText = String(localized: "Record, then turn", bundle: .module)
    /// While the back label is recorded, and once the count stops growing.
    var scanningTitleText = String(localized: "Turn slowly", bundle: .module)
    var scanSettledTitleText = String(localized: "Tap to finish", bundle: .module)
    var recordingText = String(localized: "REC", bundle: .module)
    var scanStartButtonText = String(localized: "Start recording", bundle: .module)
    var scanDoneText = String(localized: "Stop recording", bundle: .module)
    func scannedLinesText(_ count: Int) -> String {
        count == 1 ? String(localized: "1 line", bundle: .module)
            : String(localized: "\(count) lines", bundle: .module)
    }
    var readingTitleText = String(localized: "Reading", bundle: .module)
    /// What each step of the reading is doing, and its end.
    func readingStageText(_ stage: LabelReadStage?) -> String {
        switch stage {
        case .text, nil: String(localized: "Reading the text", bundle: .module)
        case .wine: String(localized: "Understanding it", bundle: .module)
        case .catalog: String(localized: "Finding the wine", bundle: .module)
        case .pairings: String(localized: "Pairing dishes", bundle: .module)
        }
    }
    var readingDoneText = String(localized: "Got it", bundle: .module)
    func readingStageIcon(_ stage: LabelReadStage) -> String {
        switch stage {
        case .text: "text.viewfinder"
        case .wine: "sparkles"
        case .catalog: "magnifyingglass"
        case .pairings: "fork.knife"
        }
    }
    var frontStepText = String(localized: "Front", bundle: .module)
    var backStepText = String(localized: "Back label", bundle: .module)
    var shutterText = String(localized: "Take photo", bundle: .module)
    var libraryText = String(localized: "Choose from library", bundle: .module)
    var cameraUnavailableText = String(localized: "No camera on this device", bundle: .module)
    var turnIcon = "arrow.left.and.right"

    // MARK: Messages (CELLAR-R21, R22)
    var errorTitleText = String(localized: "We couldn’t read your label", bundle: .module)
    var errorBodyText = String(localized: "Check these two things and try again.", bundle: .module)
    var lightTitleText = String(localized: "Light", bundle: .module)
    var lightBodyText = String(localized: "Move somewhere brighter and keep the label out of shadow.", bundle: .module)
    var wholeLabelTitleText = String(localized: "Whole label", bundle: .module)
    var wholeLabelBodyText = String(localized: "Fit the whole label inside the frame, flat and in focus.", bundle: .module)
    var notWineTitleText = String(localized: "This doesn’t look like a wine", bundle: .module)
    var notWineBodyText = String(localized: "UVVA read the label, but found no grape, no alcohol by volume and nothing else a wine label says. Photograph the bottle’s labels, front and back.", bundle: .module)
    var tryAgainText = String(localized: "Try again", bundle: .module)
    var fillInByHandText = String(localized: "Fill in by hand", bundle: .module)
    var deniedTitleText = String(localized: "The camera is off", bundle: .module)
    var deniedBodyText = String(localized: "UVVA needs the camera to read labels. Turn it on in Settings, or add the wine by hand.", bundle: .module)
    var openSettingsText = String(localized: "Open Settings", bundle: .module)

    // MARK: By hand (CELLAR-R23)
    var manualBodyText = String(localized: "Type the name and choose the rest from the lists. The type and one more detail draw the map.", bundle: .module)
    var wineFieldText = String(localized: "Wine", bundle: .module)
    var producerFieldText = String(localized: "Producer", bundle: .module)
    var regionFieldText = String(localized: "Region", bundle: .module)
    var vintageFieldText = String(localized: "Vintage", bundle: .module)
    var grapeFieldText = String(localized: "Grape", bundle: .module)
    var typeFieldText = String(localized: "Type", bundle: .module)
    var alcoholFieldText = String(localized: "Alcohol", bundle: .module)
    var alcoholPromptText = String(localized: "% vol", bundle: .module)
    var alcoholHintText = String(localized: "Between 4.5 and 23% vol", bundle: .module)
    var appellationFieldText = String(localized: "Appellation", bundle: .module)
    var designationFieldText = String(localized: "Legal term", bundle: .module)
    var notesFieldText = String(localized: "Tasting notes", bundle: .module)
    var oakFieldText = String(localized: "Time in oak", bundle: .module)
    var woodFieldText = String(localized: "Wood", bundle: .module)
    var awardsFieldText = String(localized: "Awards", bundle: .module)
    var removeText = String(localized: "Remove", bundle: .module)
    var mapBasisText = String(localized: "To draw the map, choose the type and at least a grape, region, appellation, tasting note or time in oak.", bundle: .module)
    var awardSourceText = String(localized: "Competition or critic", bundle: .module)
    var medalText = String(localized: "Medal", bundle: .module)
    var scoreText = String(localized: "Score", bundle: .module)
    var yearText = String(localized: "Year", bundle: .module)

    func vintageHint(_ year: Int) -> String {
        String(localized: "A year from 1900 to \(year)", bundle: .module)
    }

    func oakAging(_ aging: OakAging) -> String { paper.oakAging(aging) }

    func oakWood(_ wood: String) -> String { paper.oakWood(wood) }

    func medal(_ medal: WineAward.Medal) -> String {
        switch medal {
        case .trophy: String(localized: "Trophy", bundle: .module)
        case .platinum: String(localized: "Platinum", bundle: .module)
        case .doubleGold: String(localized: "Double Gold", bundle: .module)
        case .gold: String(localized: "Gold", bundle: .module)
        case .silver: String(localized: "Silver", bundle: .module)
        case .bronze: String(localized: "Bronze", bundle: .module)
        case .commended: String(localized: "Commended", bundle: .module)
        }
    }

    /// "Ouro · Decanter World Wine Awards · 2023", "95 pts · Robert Parker".
    func award(_ award: WineAward) -> String {
        let grade = award.medal.map(medal) ?? award.points.map { String(localized: "\($0) pts", bundle: .module) }
        return [grade, award.competition, award.year.map(String.init)].compactMap { $0 }.joined(separator: " · ")
    }

    /// How a chosen value reads: an aroma or a wood in the phone's language, anything else as the catalog writes it.
    func manualChip(_ value: String, field: NewNoteManualChipField) -> String {
        switch field {
        case .notes: WineCatalogText.notes(value)
        case .oakWoods: oakWood(value)
        case .region, .appellation, .designation, .grapes: value
        }
    }

    func manualChipField(_ field: NewNoteManualChipField) -> String {
        switch field {
        case .region: regionFieldText
        case .appellation: appellationFieldText
        case .designation: designationFieldText
        case .grapes: grapeFieldText
        case .notes: notesFieldText
        case .oakWoods: woodFieldText
        }
    }
    var continueText = String(localized: "Continue", bundle: .module)
    var manualErrorText = String(localized: "UVVA couldn’t read this wine. Try again.", bundle: .module)

    // MARK: The note (CELLAR-R18 to R20)
    var addText = String(localized: "Add", bundle: .module)
    var noOptionsText = String(localized: "No suggestions yet", bundle: .module)
    var checkingText = String(localized: "Checking…", bundle: .module)
    var didYouMeanText = String(localized: "Did you mean", bundle: .module)

    /// The field of a chip sheet for a word of one's own (CELLAR-R18a).
    func writePrompt(_ kind: ChipWordKind) -> String {
        switch kind {
        case .grape: String(localized: "Write a grape", bundle: .module)
        case .aroma: String(localized: "Write an aroma", bundle: .module)
        case .pairing: String(localized: "Write a dish", bundle: .module)
        case .region: String(localized: "Write a region", bundle: .module)
        case .appellation: String(localized: "Write an appellation", bundle: .module)
        }
    }

    /// Why a typed word was not taken (CELLAR-R18a).
    func chipWordRejection(_ rejection: ChipWordRejection, kind: ChipWordKind) -> String {
        switch rejection {
        case .notAWord, .unknown:
            switch kind {
            case .grape: String(localized: "This doesn’t look like a valid grape. Try another.", bundle: .module)
            case .aroma: String(localized: "This doesn’t look like a valid aroma. Try another.", bundle: .module)
            case .pairing: String(localized: "This doesn’t look like a valid dish. Try another.", bundle: .module)
            case .region: String(localized: "This doesn’t look like a valid wine region. Try another.", bundle: .module)
            case .appellation:
                String(localized: "This doesn’t look like a valid appellation. Try another.", bundle: .module)
            }
        case .modelUnavailable:
            String(localized: "We couldn’t read it on this iPhone. Turn on Apple Intelligence and try again.", bundle: .module)
        case .failed:
            String(localized: "Something went wrong checking this word. Try again.", bundle: .module)
        }
    }
    var tastedQuestionText = String(localized: "Have you had this wine?", bundle: .module)
    var yesText = String(localized: "Yes", bundle: .module)
    var noText = String(localized: "No", bundle: .module)
    var maybeText = String(localized: "Maybe", bundle: .module)
    var notePromptText = String(localized: "What stood out in the glass?", bundle: .module)
    var drinkAgainText = String(localized: "Would you drink it again?", bundle: .module)
    var addPhotoText = String(localized: "Add photo", bundle: .module)
    var changePhotoText = String(localized: "Change photo", bundle: .module)
    var photoTitleText = String(localized: "Photograph the wine", bundle: .module)
    var photoBodyText = String(localized: "The label, or the bottle as you remember it.", bundle: .module)
    var verdictRequiredText = String(localized: "Choose whether you would drink it again.", bundle: .module)
    var saveNoteText = String(localized: "Save note", bundle: .module)
    var saveErrorText = String(localized: "The note wasn’t saved. Try again.", bundle: .module)

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

import Core
import Foundation

public struct NewNoteUIModel {
    var step = NewNoteStep.checkingCamera

    // MARK: Camera
    var captureTitle = ""
    var captureBody = ""
    var captureSteps: [NewNoteCaptureStepUIModel] = []
    /// The back photo, held still while it is read.
    var readingPhoto: Data?

    // MARK: By hand
    var manualFields: [NewNoteManualFieldUIModel] = []
    var types: [NewNoteTypeUIModel] = []
    var canContinue = false

    // MARK: The note
    var title = ""
    var wine: Wine?
    var palate: PalateMap?
    var facts: [NoteFactUIModel] = []
    var servingText = ""
    var match: Int?
    var tasting = NewNoteTasting.asking
    var verdicts: [NoteVerdictUIModel] = []
    var draftNote = ""
    var canSave = false
    var canRedo = false
    var findURL: URL?

    var isWorking = false
    var errorText: String?
    var resources = NewNoteResourcesUIModel()
}

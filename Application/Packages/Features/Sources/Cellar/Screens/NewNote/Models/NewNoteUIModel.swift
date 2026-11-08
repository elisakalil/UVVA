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
    /// "Vinho Regional Alentejano · 2024".
    var subtitle = ""
    var photoFront: Data?
    var photoBack: Data?
    var facts: [NoteFactUIModel] = []
    var readingText: String?
    var structure: [NoteStructureUIModel] = []
    var aromas: String?
    var tasting = NewNoteTasting.asking
    var verdicts: [NoteVerdictUIModel] = []
    var draftNote = ""
    var canSave = false
    var canRedo = false
    var findURL: URL?

    var isWorking = false
    var isConfirmingDiscard = false
    var errorText: String?
    var resources = NewNoteResourcesUIModel()
    var noteResources = NoteResourcesUIModel()
}

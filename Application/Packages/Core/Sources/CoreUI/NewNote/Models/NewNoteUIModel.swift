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
    /// The wine on paper, as the saved note shows it too.
    var content: NotePaperContent?
    var facts: [NoteFactUIModel] = []
    var tasting = NewNoteTasting.asking
    /// A wine from the Home rated before: the first question is "Rate it again?" (CELLAR-R14a).
    var isRatedBefore = false
    var verdicts: [NoteVerdictUIModel] = []
    var draftNote = ""
    var canSave = false
    /// The photo at the top of the note: the front label, or none for a wine opened from the Home.
    var photo: Data?
    var findURL: URL?

    /// What the label reading saw at each step, in debug builds (CELLAR-R17).
    var readingDebugText: String?

    var isWorking = false
    var errorText: String?
    var resources = NewNoteResourcesUIModel()
}

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
    /// The verdict the note goes in with as it stands: the one given here, or the one a wine rated before keeps.
    var currentVerdict: Verdict?
    /// The score that goes with it, 0 to 5.
    var currentScore: Int?
    var verdicts: [NoteVerdictUIModel] = []
    var draftNote = ""
    var canSave = false
    var photoFront: Data?
    var photoBack: Data?
    var findURL: URL?

    /// What the label reading saw at each step, in debug builds (CELLAR-R17).
    var readingDebugText: String?
    /// The reading as the camera gave it, as JSON, to replay it in a test (`LabelScanExport`).
    var readingExportText: String?

    var isWorking = false
    var errorText: String?
    var resources = NewNoteResourcesUIModel()
}

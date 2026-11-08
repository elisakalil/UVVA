import Core
import Foundation

/// The steps of a new note and what each one keeps (CELLAR.md §4), with no side effects: the view model asks the
/// use cases and tells the flow what came back.
///
/// ```
/// checkingCamera → front → back → reading ─┬ found ──→ note
///      └ denied → cameraDenied             ├ unsure ─→ manual (filled) ─ Continue → note
///                                          └ failed ─→ readFailed
/// ```
struct NewNoteFlow: Equatable {
    private(set) var step = NewNoteStep.checkingCamera
    private(set) var photoFront: Data?
    private(set) var photoBack: Data?
    /// The wine read on the label or typed by hand.
    private(set) var wine: Wine?
    var manual = NewNoteManualForm()
    private(set) var tasting = NewNoteTasting.asking
    private(set) var verdict: Verdict?
    var note = ""
    private(set) var isConfirmingDiscard = false

    // MARK: Camera (CELLAR-R15, R22)

    /// Authorized opens the front photo; denied, "The camera is off". Not asked yet waits for the system request.
    mutating func cameraChecked(_ access: CameraAccess) {
        guard step == .checkingCamera else { return }
        switch access {
        case .authorized: step = .front
        case .denied: step = .cameraDenied
        case .notDetermined: break
        }
    }

    // MARK: Photos and reading (CELLAR-R16, R17, R21)

    /// The shutter: the front, then the back, then the reading.
    mutating func capture(_ photo: Data) {
        switch step {
        case .front:
            photoFront = photo
            step = .back
        case .back:
            photoBack = photo
            step = .reading
        default: break
        }
    }

    mutating func labelRead(_ result: LabelReadResult) {
        guard step == .reading else { return }
        switch result {
        case let .found(wine): show(wine)
        case let .unsure(facts):
            manual = NewNoteManualForm(facts)
            step = .manual
        case .failed: step = .readFailed
        }
    }

    /// "Try again" (CELLAR-R21): back to the front photo, without the old ones.
    mutating func tryAgain() {
        guard step == .readFailed else { return }
        startOver()
    }

    /// "Fill in by hand" from a failed reading or with the camera off (CELLAR-R21, R22).
    mutating func fillInByHand() {
        guard step == .readFailed || step == .cameraDenied else { return }
        manual = NewNoteManualForm()
        step = .manual
    }

    // MARK: By hand (CELLAR-R23)

    var canContinueManual: Bool { step == .manual && manual.canContinue }

    /// UVVA read the wine from what was typed.
    mutating func manualRead(_ wine: Wine) {
        guard canContinueManual else { return }
        show(wine)
    }

    // MARK: Redo (CELLAR-R24)

    /// The photos and the reading go; back to the front photo.
    var canRedo: Bool { photoFront != nil && [.back, .note, .manual].contains(step) }

    mutating func redo() {
        guard canRedo else { return }
        startOver()
    }

    // MARK: Have you had this wine? (CELLAR-R18, R20)

    mutating func answer(hasTasted: Bool) {
        guard step == .note else { return }
        tasting = hasTasted ? .tasted : .notYet
        if !hasTasted { verdict = nil }
    }

    mutating func pick(_ verdict: Verdict) {
        guard step == .note, tasting == .tasted else { return }
        self.verdict = verdict
    }

    /// The verdict is required; the note is not (CELLAR-R20). "Add to cellar" needs nothing.
    var canSave: Bool { draft != nil }

    var draft: NewNoteDraft? {
        guard step == .note, let wine else { return nil }
        switch tasting {
        case .asking: return nil
        case .tasted:
            guard let verdict else { return nil }
            return NewNoteDraft(wine: wine, status: .tasted, verdict: verdict, note: note,
                                photoFront: photoFront, photoBack: photoBack)
        case .notYet:
            return NewNoteDraft(wine: wine, status: .wantToTry, photoFront: photoFront, photoBack: photoBack)
        }
    }

    // MARK: Discard (CELLAR-R25)

    /// With photos, a reading or something typed, the `×` asks first.
    mutating func close() -> NewNoteCloseOutcome {
        guard photoFront != nil || wine != nil || !manual.isEmpty else { return .close }
        isConfirmingDiscard = true
        return .confirm
    }

    /// "Keep editing".
    mutating func keepEditing() { isConfirmingDiscard = false }

    // MARK: -

    private mutating func show(_ wine: Wine) {
        self.wine = wine
        tasting = .asking
        verdict = nil
        step = .note
    }

    private mutating func startOver() {
        photoFront = nil
        photoBack = nil
        wine = nil
        manual = NewNoteManualForm()
        tasting = .asking
        verdict = nil
        step = .front
    }
}

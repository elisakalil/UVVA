import Core
import Foundation

/// The steps of a new note and what each one keeps (CELLAR.md §4), with no side effects: the view model asks the
/// use cases and tells the flow what came back.
///
/// ```
/// checkingCamera → front → back → reading ─┬ read ────→ note
///      └ denied → cameraDenied             ├ nameless → manual (filled) ─ Continue → note
///                                          └ failed ──→ readFailed
/// ```
/// A wine the app already knows, from the Home's wine sheet, starts at `note` (CELLAR-R14a). The sheet is dragged
/// down to close at any step, and nothing is kept (CELLAR-R25).
struct NewNoteFlow: Equatable {
    private(set) var step = NewNoteStep.checkingCamera
    private(set) var photoFront: Data?
    private(set) var photoBack: Data?
    /// The wine read on the label or typed by hand.
    private(set) var wine: Wine?
    private var originalWine: Wine?
    var manual = NewNoteManualForm()
    private(set) var tasting = NewNoteTasting.asking
    private(set) var verdict: Verdict?
    /// The verdict a wine from the Home was rated with before (CELLAR-R14a): the note asks "Rate it again?" instead of
    /// "Have you had this wine?", and keeps it unless a new one is given.
    private(set) var ratedVerdict: Verdict?
    var note = ""
    /// A saved note opened to be edited (CELLAR-R27): its note is replaced as written when saved.
    private(set) var isEditing = false

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
        case let .read(wine): show(wine)
        case let .nameless(facts):
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

    // MARK: The photo (CELLAR-R24)

    /// A new photo of the wine, taken over the note: it replaces the one at the top and keeps what was read and
    /// written.
    mutating func replacePhoto(_ photo: Data) {
        guard step == .note else { return }
        photoFront = photo
    }

    // MARK: Have you had this wine? (CELLAR-R18, R20)

    /// "Have you had this wine?" (or, for a wine rated before, "Rate it again?"): Yes asks for the verdict. No keeps
    /// the verdict the wine had; Not yet leaves it untasted.
    mutating func answer(hasTasted: Bool) {
        guard step == .note else { return }
        if hasTasted {
            tasting = .tasted
        } else if let ratedVerdict {
            tasting = .keptRating
            verdict = ratedVerdict
        } else {
            tasting = .notYet
            verdict = nil
        }
    }

    mutating func pick(_ verdict: Verdict) {
        guard step == .note, tasting == .tasted else { return }
        self.verdict = verdict
    }

    mutating func addChip(_ value: String, to field: NewNoteChipField) {
        guard step == .note, var wine else { return }
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let chips = field.values(in: wine)
        guard !value.isEmpty, !chips.contains(where: { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }) else { return }
        switch field {
        case .grapes: wine.grapes.append(value)
        case .notes: wine.note = (chips + [value]).joined(separator: ", ")
        case .pairings: wine.pairings.append(value)
        }
        self.wine = wine
    }

    mutating func setIntensity(_ value: Double, for axis: PalateAxis) {
        guard step == .note, var wine else { return }
        var values = wine.profile.values
        values[axis] = value
        wine.profile = PalateMap(values)
        self.wine = wine
    }

    /// "Save note" is always there; it only keeps the note when it is whole: a tasted wine needs its verdict. The
    /// free note is optional.
    var canSave: Bool { draft != nil }

    /// "Yes" asked for the verdict and none was given yet.
    var needsVerdict: Bool { step == .note && tasting == .tasted && verdict == nil }

    var draft: NewNoteDraft? {
        guard step == .note, let wine else { return nil }
        switch tasting {
        case .tasted, .keptRating:
            guard let verdict else { return nil }
            return NewNoteDraft(wine: wine, status: .tasted, verdict: verdict, note: note,
                                photoFront: photoFront, photoBack: photoBack, originalWine: originalWine,
                                replacesNote: isEditing)
        // Unanswered, a wine rated before keeps its verdict and goes in as Tasted.
        case .asking where ratedVerdict != nil:
            return NewNoteDraft(wine: wine, status: .tasted, verdict: ratedVerdict, note: note,
                                photoFront: photoFront, photoBack: photoBack, originalWine: originalWine,
                                replacesNote: isEditing)
        // Unanswered, the wine has not been tasted as far as the note knows: it goes in as Not yet.
        case .asking, .notYet:
            return NewNoteDraft(wine: wine, status: .wantToTry, note: note.isEmpty ? nil : note,
                                photoFront: photoFront, photoBack: photoBack, originalWine: originalWine,
                                replacesNote: isEditing)
        }
    }

    // MARK: -

    private mutating func show(_ wine: Wine) {
        self.wine = wine
        originalWine = wine
        tasting = .asking
        verdict = nil
        step = .note
    }

    private mutating func startOver() {
        photoFront = nil
        photoBack = nil
        wine = nil
        originalWine = nil
        note = ""
        manual = NewNoteManualForm()
        tasting = .asking
        verdict = nil
        step = .front
    }
}

extension NewNoteFlow {
    /// CELLAR-R14a: a wine from the Home's Hero or wine sheet opens on paper, with no photos, asking "Have you had
    /// this wine?"; one rated before (`ratedVerdict`) is asked "Rate it again?" instead.
    init(wine: Wine, ratedVerdict: Verdict? = nil) {
        self.wine = wine
        originalWine = wine
        self.ratedVerdict = ratedVerdict
        step = .note
    }

    /// CELLAR-R27: a saved note, opened here to be edited, with its verdict, its note and its photos. A wine not
    /// tasted yet is asked "Have you had this wine?" again.
    init(editing wine: Wine, verdict: Verdict?, note: String?, photoFront: Data?, photoBack: Data?) {
        self.init(wine: wine)
        self.verdict = verdict
        if verdict != nil { tasting = .tasted }
        self.note = note ?? ""
        self.photoFront = photoFront
        self.photoBack = photoBack
        isEditing = true
    }
}

import Foundation

/// What a new note saves (CELLAR.md §4): the wine read on the label, Tasted with its verdict or Want to try,
/// the free note and the two photos.
public struct NewNoteDraft: Equatable, Sendable {
    public var wine: Wine
    public var status: CellarEntryStatus
    /// Only for Tasted (CELLAR-R01).
    public var verdict: Verdict?
    public var note: String?
    public var photoFront: Data?
    public var photoBack: Data?

    public init(wine: Wine, status: CellarEntryStatus, verdict: Verdict? = nil, note: String? = nil,
                photoFront: Data? = nil, photoBack: Data? = nil) {
        self.wine = wine
        self.status = status
        self.verdict = status == .tasted ? verdict : nil
        self.note = note
        self.photoFront = photoFront
        self.photoBack = photoBack
    }
}

import Core

/// One answer to "Would you drink it again?" while editing.
struct NoteVerdictUIModel: Identifiable, Equatable {
    var verdict: Verdict
    var label: String
    var isSelected: Bool
    var id: String { verdict.rawValue }
}

import Core

/// One answer to "Would you drink it again?" while editing.
public struct NoteVerdictUIModel: Identifiable, Equatable {
    public var verdict: Verdict
    public var label: String
    public var isSelected: Bool
    public var id: String { verdict.rawValue }
    public init(verdict: Verdict, label: String, isSelected: Bool) {
        self.verdict = verdict
        self.label = label
        self.isSelected = isSelected
    }

}

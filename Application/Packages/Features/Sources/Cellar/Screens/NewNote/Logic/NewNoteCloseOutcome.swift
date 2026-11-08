import Foundation

/// What the `×` does (CELLAR-R25).
enum NewNoteCloseOutcome: Equatable {
    /// Nothing to lose: the new note closes.
    case close
    /// "Discard this note?" first.
    case confirm
}

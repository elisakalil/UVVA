import Foundation

/// The fields of "Fill in by hand" that are typed (CELLAR-R23); the rest are chosen from lists.
public enum NewNoteField: CaseIterable, Sendable {
    case name, producer, vintage, alcohol
}

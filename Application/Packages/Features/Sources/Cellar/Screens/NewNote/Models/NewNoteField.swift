import Foundation

/// A field of "Fill in by hand" (CELLAR-R23).
public enum NewNoteField: CaseIterable, Sendable {
    case name, producer, region, vintage, grape
}

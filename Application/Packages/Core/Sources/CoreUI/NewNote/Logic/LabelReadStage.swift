import Foundation

/// Where "Reading your label" is (CELLAR-R17), so the camera shows each step as it passes instead of a line that
/// waits at the end.
enum LabelReadStage: Int, CaseIterable, Comparable {
    /// The text of the two photos (Vision).
    case text
    /// The text sorted into a wine: the parser and the model on the phone.
    case wine
    /// The wine looked up in the catalog on the phone, then in the public one.
    case catalog
    /// Dishes added to the pairings.
    case pairings

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

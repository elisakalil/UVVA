import Core
import Foundation

/// A field of "Fill in by hand" chosen from a list or typed (CELLAR-R23): a typed word is taken only once UVVA checks
/// it (CELLAR-R18a), so nothing made up draws the map (CELLAR-R23a).
public enum NewNoteManualChipField: String, CaseIterable, Identifiable, Sendable {
    case region, appellation, designation, grapes, notes, oakWoods

    public var id: String { rawValue }

    /// Grapes, notes and woods add up; a region, an appellation or a legal term is one.
    var allowsMany: Bool {
        switch self {
        case .grapes, .notes, .oakWoods: true
        case .region, .appellation, .designation: false
        }
    }

    /// What a word typed for it must name; nil for the fixed lists, which are only chosen from (CELLAR-R18a).
    var wordKind: ChipWordKind? {
        switch self {
        case .region: .region
        case .appellation: .appellation
        case .grapes: .grape
        case .notes: .aroma
        case .designation, .oakWoods: nil
        }
    }

    /// What can be chosen: the catalog's own values, the most frequent first; the legal terms and the woods are
    /// fixed lists.
    func options(in wines: [Wine]) -> [String] {
        switch self {
        case .designation: CertificationKeywords.designationNames
        case .oakWoods: OakWood.all
        case .region: NewNoteChipField.ranked(wines) { [$0.region].compactMap { $0 } }
        case .appellation: NewNoteChipField.ranked(wines) { [$0.appellation].compactMap { $0 } }
        case .grapes: NewNoteChipField.ranked(wines, values: \.grapes)
        case .notes: NewNoteChipField.ranked(wines, values: \.noteItems)
        }
    }
}

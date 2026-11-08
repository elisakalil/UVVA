import Core

/// The four lines of the structure in UVVA's reading, in the artboard's order (CELLAR-R26).
enum NoteStructureRow: CaseIterable {
    case body, tannin, acidity, sweetness

    var axis: PalateAxis {
        switch self {
        case .body: .body
        case .tannin: .tannin
        case .acidity: .acidity
        case .sweetness: .sweetness
        }
    }
}

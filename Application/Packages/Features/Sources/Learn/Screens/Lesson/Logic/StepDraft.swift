import Foundation

/// The learner's work on one question step while it is on screen, before and after "Check".
struct StepDraft: Equatable {
    /// multipleChoice, selectMultiple and trueFalse (0 is True, 1 is False).
    var selection: Set<Int> = []
    var word: String?
    /// ordering: item indexes in the order shown.
    var order: [Int] = []
    /// ordering: the row picked first, waiting for the row to swap with.
    var pickedRow: Int?
    /// matchPairs: the pairs linked, by pair index.
    var links: Set<Int> = []
    /// matchPairs: the term tapped, waiting for its match.
    var pickedLeft: Int?
    /// matchPairs: the last wrong try, shown until the next tap.
    var miss: Miss?
    var misses = 0
    var isChecked = false

    struct Miss: Equatable {
        var left: Int
        var right: Int
    }
}

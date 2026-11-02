import Foundation

/// One option of a choice, a word of a fillBlank, a row of an ordering or a term of a matchPairs.
struct OptionUIModel: Identifiable, Equatable {
    var id: Int
    /// "01", or empty where nothing is numbered.
    var number: String
    var label: String
    var state: OptionState
}

import Foundation

/// One option of a choice, a word of a fillBlank, a row of an ordering or a term of a matchPairs.
struct OptionUIModel: Identifiable, Equatable {
    var id: Int
    /// "01", or empty where nothing is numbered.
    var number: String
    var label: String
    var state: OptionState
    /// What the option is, wherever it sits: ordering rows glide by it when swapped. Defaults to `id`.
    var key: Int

    init(id: Int, number: String, label: String, state: OptionState, key: Int? = nil) {
        self.id = id
        self.number = number
        self.label = label
        self.state = state
        self.key = key ?? id
    }
}

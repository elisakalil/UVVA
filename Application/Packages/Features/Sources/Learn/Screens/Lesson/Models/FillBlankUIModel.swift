import Foundation

struct FillBlankUIModel: Equatable {
    var before: String
    var after: String
    /// The word in the blank, once one is picked.
    var word: String?
    var wordState: OptionState
    var options: [OptionUIModel]
}

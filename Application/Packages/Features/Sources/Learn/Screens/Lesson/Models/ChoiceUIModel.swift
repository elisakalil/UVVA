import Foundation

/// multipleChoice, selectMultiple and trueFalse.
struct ChoiceUIModel: Equatable {
    var kind: ChoiceKind
    var prompt: String
    var options: [OptionUIModel]
}

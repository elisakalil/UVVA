import Foundation

/// multipleChoice, selectMultiple and trueFalse.
struct ChoiceUIModel: Equatable {
    var kind: ChoiceKind
    /// "Choose one", "Select all that apply", "True or false".
    var eyebrow: String
    var prompt: String
    var options: [OptionUIModel]
}

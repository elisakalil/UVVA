import Foundation

struct OrderingUIModel: Equatable {
    var prompt: String
    /// "Tap two items to swap them." or "Now tap where it should go."
    var hint: String
    var rows: [OptionUIModel]
}

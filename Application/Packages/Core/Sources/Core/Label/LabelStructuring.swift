import Foundation

/// Sorts the text of a label into the wine's facts with the model on the phone (Foundation Models, iOS 26).
public protocol LabelStructuring: Sendable {
    /// Nil when the model is not available on this phone, or could not tell: the parser does the work alone.
    func structure(_ text: LabelText) async -> LabelFacts?
}

import Foundation

/// Sorts the text of a label into the wine's facts with the model on the phone (Foundation Models, iOS 26).
public protocol LabelStructuring: Sendable {
    /// No facts when the model is not available on this phone, or could not tell: the parser does the work alone.
    func structure(_ text: LabelText) async -> LabelStructuringResult
}

/// What the model on the phone made of a label, and why it made nothing.
public struct LabelStructuringResult: Equatable, Sendable {
    public var facts: LabelFacts?
    /// Why there are no facts, in plain words, for the debug section of the note (CELLAR-R17).
    public var failure: String?
    /// The phone as the model saw it: "iOS 26.1 · pt-PT · language supported".
    public var context: String?

    public init(facts: LabelFacts? = nil, failure: String? = nil, context: String? = nil) {
        self.facts = facts
        self.failure = failure
        self.context = context
    }
}

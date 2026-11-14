import Foundation

/// Suggests dishes for a wine with the model on the phone (Foundation Models, iOS 26), from everything known of it:
/// what the catalog has, what its label says, and the pairings found so far (CELLAR-R17).
public protocol PairingSuggesting: Sendable {
    /// Dishes to add to `wine.pairings`, none of them already there. Nothing when the model is not available.
    func suggestPairings(for wine: Wine) async -> PairingSuggestionResult
}

/// What the model on the phone added to a wine's pairings, and why it added nothing.
public struct PairingSuggestionResult: Equatable, Sendable {
    public var pairings: [String]
    /// Why there are no pairings, in plain words, for the debug section of the note.
    public var failure: String?

    public init(pairings: [String] = [], failure: String? = nil) {
        self.pairings = pairings
        self.failure = failure
    }
}

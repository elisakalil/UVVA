import Core
import Foundation

extension PairingSuggesting {
    /// From this many pairings the model is not asked for more: a wine scanned again and again would otherwise gain
    /// three each time. The label's own are never cut.
    static var enoughPairings: Int { 10 }

    /// The wine with the dishes the model adds to the pairings it has (CELLAR-R17), and the dishes it really added
    /// (or why none); no answer when the wine already has enough.
    func enriching(_ wine: Wine) async -> (wine: Wine, suggestion: PairingSuggestionResult?) {
        guard wine.pairings.count < Self.enoughPairings else { return (wine, nil) }
        let suggestion = await suggestPairings(for: wine)
        var enriched = wine
        enriched.pairings = wine.pairings.adding(suggestion.pairings)
        let added = enriched.pairings.filter { dish in
            !wine.pairings.contains { $0.caseInsensitiveCompare(dish) == .orderedSame }
        }
        let failure = added.isEmpty ? suggestion.failure ?? "The model gave no new dish." : nil
        return (enriched, PairingSuggestionResult(pairings: added, failure: failure))
    }
}

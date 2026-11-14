import Core
import Foundation
import Match

/// The catalog prepared for label lookups, read once per new note: the index of names, the vocabulary of grapes and
/// places, and every wine for estimating a map.
@MainActor
final class LabelCatalogCache {
    struct Prepared {
        var wines: [Wine]
        var index: LabelCatalogIndex
        var vocabulary: LabelVocabulary
    }

    private let catalog: any LabelCatalogRepository
    private var prepared: Prepared?

    init(catalog: any LabelCatalogRepository) {
        self.catalog = catalog
    }

    func load() async throws -> Prepared {
        if let prepared { return prepared }
        let wines = try await catalog.allWines()
        // 10 000 wines: built off the main actor.
        let built = await Task.detached(priority: .userInitiated) {
            Prepared(wines: wines, index: LabelCatalogIndex(wines: wines), vocabulary: LabelVocabulary(wines: wines))
        }.value
        prepared = built
        return built
    }

    /// The label's wine in the public catalog, when the phone's copy does not have it (ARCHITECTURE §4.1): asked by
    /// the words of its name and producer. The wines found stay on the phone; the next note reads them with the rest.
    /// Nil without a network or a confident match.
    func publicMatch(for facts: LabelFacts) async -> LabelMatchResult? {
        var tokens = WineText.significantTokens([facts.name, facts.producer].compactMap { $0 }.joined(separator: " "))
        if tokens.isEmpty { tokens = WineText.significantTokens(facts.titleLines.joined(separator: " ")) }
        guard let wines = try? await catalog.publicWines(sharing: tokens), !wines.isEmpty else { return nil }
        prepared = nil
        guard let match = LabelMatch.best(for: facts, in: LabelCatalogIndex(wines: wines)), match.isConfident else {
            return nil
        }
        return match
    }
}

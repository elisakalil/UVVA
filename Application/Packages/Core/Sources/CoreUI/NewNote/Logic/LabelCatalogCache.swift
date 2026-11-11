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
}

import Core
import Foundation
import Match

@MainActor
struct ReadManualUseCase: ReadManualUseCaseProtocol {
    enum Failure: Error { case emptyCatalog }

    let catalog: LabelCatalogCache

    func execute(_ facts: LabelFacts) async throws -> Wine {
        let prepared = try await catalog.load()
        var typed = canonical(facts, in: prepared.vocabulary)
        typed.titleLines = [typed.name, typed.producer].compactMap { $0 }
        if let match = LabelMatch.best(for: typed, in: prepared.index), match.isConfident {
            return match.wine
        }
        guard let profile = ProfileEstimate.estimate(grapes: typed.grapes, type: typed.type, region: typed.region,
                                                     in: prepared.wines) else { throw Failure.emptyCatalog }
        return ScannedWine.make(typed, profile: profile)
    }

    /// The grapes and region as the catalog spells them ("syrah" → "Syrah", "Dao" → "Dão"), so the estimate finds
    /// their wines; a name the catalog does not know stays as typed.
    private func canonical(_ facts: LabelFacts, in vocabulary: LabelVocabulary) -> LabelFacts {
        func lookup(_ text: String, in names: some Collection<String>) -> String {
            let folded = WineText.tokens(text)
            return names.first { WineText.tokens($0) == folded } ?? text
        }
        var result = facts
        result.grapes = facts.grapes.map { lookup($0, in: vocabulary.grapeTypes.keys) }
        if let region = facts.region {
            let regions = Set(vocabulary.regionCountries.keys)
            let appellations = Set(vocabulary.appellationRegions.keys)
            let asRegion = lookup(region, in: regions)
            if regions.contains(asRegion) {
                result.region = asRegion
            } else {
                let appellation = lookup(region, in: appellations)
                result.appellation = appellations.contains(appellation) ? appellation : nil
                result.region = vocabulary.appellationRegions[appellation] ?? region
            }
            result.country = result.region.flatMap { vocabulary.regionCountries[$0] }
        }
        return result
    }
}

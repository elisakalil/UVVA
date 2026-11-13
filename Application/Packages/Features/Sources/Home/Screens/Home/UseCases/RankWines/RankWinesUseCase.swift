import Core
import Foundation
import Match

/// The new wines of the catalog, closest to the map first, with the dish of the wine at the top (HOME-R06, R07, R08):
/// the Hero is that one wine, so only it is paired. A wine no recipe goes with gives its place to the next. Wines in
/// the Cellar, tasted or not, are left out (HOME-R08a): every card that suggests a wine reads this list.
///
/// Nothing here runs on the main actor but the hand-offs: the ranking of the 10,000 wines and the recipes are read on
/// the catalog's own queue, and the Cellar's wines are taken out and the dish chosen in a detached task.
@MainActor
struct RankWinesUseCase: RankWinesUseCaseProtocol {
    let catalog: any CatalogRepository

    func execute(for map: PalateMap, excluding cellarWineKeys: Set<String>) async throws -> [Wine] {
        // The whole catalog: an axis match can sit anywhere in the overall similarity ranking.
        let ranked = try await catalog.winesClosest(to: map, limit: .max)
        let recipes = try await catalog.recipes()
        return await Task.detached(priority: .userInitiated) {
            Self.paired(Self.newWines(ranked, excluding: cellarWineKeys), for: map, among: recipes)
        }.value
    }

    func narrow(_ ranked: [Wine], excluding cellarWineKeys: Set<String>, for map: PalateMap) async throws -> [Wine] {
        let (wines, keptDish) = await Task.detached(priority: .userInitiated) {
            let wines = Self.newWines(ranked, excluding: cellarWineKeys)
            return (wines, wines.contains { $0.dish != nil })
        }.value
        // The paired wine is still new: the list keeps its dish. Otherwise the next wine with a recipe takes it.
        guard !keptDish else { return wines }
        let recipes = try await catalog.recipes()
        return await Task.detached(priority: .userInitiated) {
            Self.paired(wines, for: map, among: recipes)
        }.value
    }

    nonisolated private static func newWines(_ ranked: [Wine], excluding cellarWineKeys: Set<String>) -> [Wine] {
        cellarWineKeys.isEmpty ? ranked : ranked.filter { !cellarWineKeys.contains($0.id) }
    }

    /// The first wine a recipe goes with gets its dish. The wines come without one: from the catalog, or from a list
    /// whose paired wine has just gone to the Cellar.
    nonisolated private static func paired(_ ranked: [Wine], for map: PalateMap, among recipes: [Recipe]) -> [Wine] {
        var wines = ranked
        for index in wines.indices {
            guard let recipe = Pairing.recipe(for: wines[index], user: map, among: recipes) else { continue }
            wines[index].dish = Pairing.dish(from: recipe)
            break
        }
        return wines
    }
}

import Core
import Foundation
import Match

/// The catalog, closest to the map first, with the dish of the wine at the top (HOME-R06, R07): the Hero is that one
/// wine, so only it is paired. A wine no recipe goes with gives its place to the next.
@MainActor
struct RankWinesUseCase: RankWinesUseCaseProtocol {
    let catalog: any CatalogRepository

    func execute(for map: PalateMap) async throws -> [Wine] {
        // The whole catalog: an axis match can sit anywhere in the overall similarity ranking.
        let ranked = try await catalog.winesClosest(to: map, limit: .max)
        let recipes = try await catalog.recipes()

        // Only Sendable values cross into the background task.
        return await Task.detached(priority: .userInitiated) {
            var wines = ranked
            for index in wines.indices {
                guard let recipe = Pairing.recipe(for: wines[index], user: map, among: recipes) else { continue }
                wines[index].dish = Pairing.dish(from: recipe)
                break
            }
            return wines
        }.value
    }
}

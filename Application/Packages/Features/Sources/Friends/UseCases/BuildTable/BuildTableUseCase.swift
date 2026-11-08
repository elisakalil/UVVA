import Core
import Foundation
import Match

/// FRI-R14: the bottles come from `TableMatch.tableBottles`, over the whole catalog on the device, off the main thread.
@MainActor
struct BuildTableUseCase: BuildTableUseCaseProtocol {
    let catalog: any CatalogRepository

    func execute(maps: [PalateMap]) async throws -> [TableBottle] {
        let wines = try await catalog.winesClosest(to: TableMatch.crossed(maps), limit: .max)
        let recipes = try await catalog.recipes()
        return await Task.detached(priority: .userInitiated) {
            TableMatch.tableBottles(maps, wines: wines, recipes: recipes)
        }.value
    }
}

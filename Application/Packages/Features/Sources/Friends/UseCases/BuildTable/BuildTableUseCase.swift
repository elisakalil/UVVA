import Core
import Foundation
import Match

/// FRI-R14: the bottles come from `TableMatch.tableBottles`, over the whole catalog on the device, off the main thread.
@MainActor
struct BuildTableUseCase: BuildTableUseCaseProtocol {
    let catalog: any CatalogRepository
    var now: () -> Date = Date.init

    func execute(maps: [PalateMap], preferences: DinnerPreferences) async throws -> [TableBottle] {
        let wines = try await catalog.winesClosest(to: TableMatch.crossed(maps), limit: .max)
        // FRI-R13a: only the dishes that fit the dinner chosen.
        let recipes = preferences.recipes(from: try await catalog.recipes(), on: now())
        let courses = preferences.courses
        return await Task.detached(priority: .userInitiated) {
            TableMatch.tableBottles(maps, wines: wines, recipes: recipes, courses: courses)
        }.value
    }

    func wines(for map: PalateMap, limit: Int) async throws -> [Wine] {
        try await catalog.winesClosest(to: map, limit: limit)
    }
}

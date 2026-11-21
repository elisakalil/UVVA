import Core
import Foundation

@MainActor
protocol BuildTableUseCaseProtocol {
    /// The bottles and their dishes for everyone at the table (FRI-R14): Starter, Main and Dessert, or the dinner the
    /// user chose (FRI-R13a).
    func execute(maps: [PalateMap], preferences: DinnerPreferences) async throws -> [TableBottle]
    /// The bottles of the catalog closest to one map, best first: "Picks for [name]" (FRI-R11).
    func wines(for map: PalateMap, limit: Int) async throws -> [Wine]
}

extension BuildTableUseCaseProtocol {
    func execute(maps: [PalateMap]) async throws -> [TableBottle] {
        try await execute(maps: maps, preferences: DinnerPreferences())
    }
}

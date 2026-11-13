import Core

@MainActor
protocol RankWinesUseCaseProtocol {
    /// The whole catalog ranked on `map`, without the wines in the Cellar, the first with a recipe paired (HOME-R08a).
    func execute(for map: PalateMap, excluding cellarWineKeys: Set<String>) async throws -> [Wine]
    /// A list from `execute` once more wines went to the Cellar: they leave it, and the next wine with a recipe takes
    /// the dish if the paired one left. The map is the one `ranked` was ranked on; nothing is ranked again.
    func narrow(_ ranked: [Wine], excluding cellarWineKeys: Set<String>, for map: PalateMap) async throws -> [Wine]
}

import Core

@MainActor
protocol RankWinesUseCaseProtocol {
    func execute(for map: PalateMap) async throws -> [Wine]
}

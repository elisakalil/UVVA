import Core
import Foundation
import Match
@testable import Home

/// What the match cards follow, as the test sets it (HOME-R10c).
@MainActor
final class PalateStateStub: LoadPalateStateUseCaseProtocol {
    var state: PalateStateModel
    private(set) var calls = 0

    init(_ model: HomeContentModel = .full, cellarWineKeys: Set<String> = []) {
        state = PalateStateModel(palateMap: model.palateMap, ratedVerdicts: model.ratedVerdicts,
                                 lastRating: model.lastRating, cellarWineKeys: cellarWineKeys)
    }

    func execute() async throws -> PalateStateModel {
        calls += 1
        return state
    }
}

/// The preview catalog ranked on the map it is asked for, without the Cellar's wines, the top with a dish, as the
/// store and the pairing give it.
@MainActor
final class WineRankingSpy: RankWinesUseCaseProtocol {
    /// Full rankings.
    private(set) var calls = 0
    /// Lists narrowed after wines went to the Cellar, with no new ranking.
    private(set) var narrowCalls = 0

    func execute(for map: PalateMap, excluding cellarWineKeys: Set<String>) async throws -> [Wine] {
        calls += 1
        let ranked = HomeContentModel.full.catalog
            .map { wine -> Wine in var wine = wine; wine.dish = nil; return wine }
            .sorted {
                let (l, r) = (Similarity.between($0.profile, map), Similarity.between($1.profile, map))
                return l == r ? $0.id < $1.id : l > r
            }
        return Self.paired(ranked.filter { !cellarWineKeys.contains($0.id) })
    }

    func narrow(_ ranked: [Wine], excluding cellarWineKeys: Set<String>, for map: PalateMap) async throws -> [Wine] {
        narrowCalls += 1
        let wines = ranked.filter { !cellarWineKeys.contains($0.id) }
        return wines.contains { $0.dish != nil } ? wines : Self.paired(wines)
    }

    private static func paired(_ wines: [Wine]) -> [Wine] {
        var wines = wines
        if !wines.isEmpty { wines[0].dish = Dish(title: "Paired", why: "Top of the list.") }
        return wines
    }
}

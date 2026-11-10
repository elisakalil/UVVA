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
        state = PalateStateModel(palateMap: model.palateMap, ratedWineIDs: model.ratedWineIDs,
                                 lastRating: model.lastRating, cellarWineKeys: cellarWineKeys)
    }

    func execute() async throws -> PalateStateModel {
        calls += 1
        return state
    }
}

/// The preview catalog ranked on the map it is asked for, the top with a dish, as the store and the pairing give it.
@MainActor
final class WineRankingSpy: RankWinesUseCaseProtocol {
    private(set) var calls = 0

    func execute(for map: PalateMap) async throws -> [Wine] {
        calls += 1
        var ranked = HomeContentModel.full.catalog
            .map { wine -> Wine in var wine = wine; wine.dish = nil; return wine }
            .sorted {
                let (l, r) = (Similarity.between($0.profile, map), Similarity.between($1.profile, map))
                return l == r ? $0.id < $1.id : l > r
            }
        if !ranked.isEmpty { ranked[0].dish = Dish(title: "Paired", why: "Top of the list.") }
        return ranked
    }
}

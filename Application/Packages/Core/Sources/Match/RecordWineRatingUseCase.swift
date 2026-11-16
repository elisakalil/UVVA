import Core
import Foundation

/// Replaces a rating made since the last Quiz, or applies the first rating to the current map.
@MainActor
public struct RecordWineRatingUseCase {
    private let maps: any PalateMapRepository
    private let recalculate: any RecalculateMapUseCaseProtocol

    public init(maps: any PalateMapRepository, recalculate: any RecalculateMapUseCaseProtocol) {
        self.maps = maps
        self.recalculate = recalculate
    }

    public func execute(_ verdict: Verdict, for wineKey: String, profile: PalateMap, at now: () -> Date) async throws {
        if let old = Rating.verdicts(in: try await maps.history())[wineKey] {
            if old != verdict { try await recalculate.execute(changing: wineKey, to: verdict, at: now()) }
        } else if let map = try await maps.currentMap() {
            let update = MapUpdate.apply(verdict, wine: profile, to: map)
            try await maps.saveRatedMap(update.map, wineKey: wineKey, verdict: verdict, at: now())
        }
    }
}

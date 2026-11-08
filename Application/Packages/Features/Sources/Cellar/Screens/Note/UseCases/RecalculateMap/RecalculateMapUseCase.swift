import Core
import Match

/// CELLAR-R29: from the last Quiz, the ratings that still exist are applied again in date order.
@MainActor
struct RecalculateMapUseCase: RecalculateMapUseCaseProtocol {
    let history: any PalateMapRepository
    let rewriter: any PalateHistoryRewriting
    let wines: any WineLookup

    func execute(changing wineKey: String, to verdict: Verdict?) async throws {
        let current = try await history.history()
        let keys = Set(current.compactMap { change -> String? in
            if case let .rating(key, _) = change.cause { key } else { nil }
        })
        // A wine rated before the last Quiz is not in this map's history: nothing to change.
        guard keys.contains(wineKey) else { return }
        let rebuilt = MapRebuild.rebuild(current, wines: try await wines.wines(keys: keys), changing: wineKey, to: verdict)
        guard rebuilt != current else { return }
        try await rewriter.rewriteHistory(rebuilt)
    }
}

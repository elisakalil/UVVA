import Core
import Foundation
import Match
import Testing

struct MapRebuildTests {
    private func flat(_ value: Double) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
    }

    private func wine(_ id: String, _ value: Double) -> Wine {
        Wine(id: id, name: id, origin: "", profile: flat(value))
    }

    /// The Quiz at 4, then the ratings, applied one after the other as the Home does.
    private func history(_ ratings: [(Wine, Verdict)]) -> [MapChange] {
        var map = flat(4)
        var changes = [MapChange(date: Date(timeIntervalSince1970: 0), cause: .quiz, values: map.values)]
        for (index, (wine, verdict)) in ratings.enumerated() {
            map = MapUpdate.apply(verdict, wine: wine.profile, to: map).map
            changes.append(MapChange(date: Date(timeIntervalSince1970: Double(index + 1)),
                                     cause: .rating(wineKey: wine.id, verdict: verdict), values: map.values))
        }
        return changes
    }

    // MARK: CELLAR-R29 · Recalcular o mapa

    @Test func CELLAR_R29_delete_leavesTheMapAsIfNeverRated() {
        let a = wine("a", 9), b = wine("b", 1)
        let rebuilt = MapRebuild.rebuild(history([(a, .yes), (b, .yes)]), wines: ["a": a, "b": b], changing: "a", to: nil)
        #expect(rebuilt == history([(b, .yes)]).enumerated().map { index, change in
            // Same values; the remaining rating keeps its own date.
            index == 0 ? change : MapChange(date: Date(timeIntervalSince1970: 2), cause: change.cause, values: change.values)
        })
    }

    @Test func CELLAR_R29_edit_reappliesWithTheNewVerdict() {
        let a = wine("a", 9), b = wine("b", 1)
        let rebuilt = MapRebuild.rebuild(history([(a, .yes), (b, .maybe)]), wines: ["a": a, "b": b], changing: "a", to: .no)
        #expect(rebuilt.map(\.values) == history([(a, .no), (b, .maybe)]).map(\.values))
        #expect(rebuilt[1].cause == .rating(wineKey: "a", verdict: .no))
    }

    @Test func wineMissingFromTheCatalog_keepsItsMove() {
        let a = wine("a", 9), scanned = wine("scanned", 1)
        let original = history([(scanned, .yes), (a, .yes)])
        let rebuilt = MapRebuild.rebuild(original, wines: ["a": a], changing: "a", to: .yes)
        #expect(rebuilt == original)
    }

    @Test func historyWithoutTheQuiz_staysAsItWas() {
        let change = MapChange(date: .now, cause: .rating(wineKey: "a", verdict: .yes), values: flat(5).values)
        #expect(MapRebuild.rebuild([change], wines: [:], changing: "a", to: nil) == [change])
    }
}

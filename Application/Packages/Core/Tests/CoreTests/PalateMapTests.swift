import Testing
@testable import Core

struct PalateMapTests {
    // MARK: QUIZ-R04 · Intensidade

    @Test func QUIZ_R04_valuesOutsideTheScale_areClamped() {
        let map = PalateMap([.acidity: 12, .oak: -3])
        #expect(map[.acidity] == 9)
        #expect(map[.oak] == 0)
    }

    @Test func QUIZ_R04_missingAxis_isZero() {
        #expect(PalateMap([:])[.fruit] == 0)
    }

    // MARK: QUIZ-R14 · Ranking

    @Test func QUIZ_R14_ranking_tiesFollowCanonicalOrder() {
        let map = PalateMap([.sweetness: 1, .acidity: 4, .tannin: 3, .body: 3, .fruit: 4, .floral: 2, .oak: 2, .spice: 3])
        #expect(map.ranked == [.acidity, .fruit, .body, .tannin, .spice, .floral, .oak, .sweetness])
    }

    @Test func QUIZ_R14_allEqual_topThreeIsFloralBodyTannin_weakestIsFruit() {
        let map = PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 5.0) }))
        #expect(Array(map.ranked.prefix(3)) == [.floral, .body, .tannin])
        #expect(map.ranked.last == .fruit)
    }
}

import Core
import Testing
@testable import Match

struct MapUpdateTests {
    private func map(_ values: [PalateAxis: Double], rest: Double = 5) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, values[$0] ?? rest) }))
    }

    private func acidity(after verdict: Verdict, from user: Double, wine: Double) -> Double {
        MapUpdate.apply(verdict, wine: map([.acidity: wine]), to: map([.acidity: user])).map[.acidity]
    }

    // MARK: QUIZ-R22 · Atualização

    @Test func QUIZ_R22_yes_movesTenPercentCloser() {
        #expect(abs(acidity(after: .yes, from: 2, wine: 8) - 2.6) < 1e-9)
    }

    @Test func QUIZ_R22_maybe_movesThreePercentCloser() {
        #expect(abs(acidity(after: .maybe, from: 2, wine: 8) - 2.18) < 1e-9)
    }

    @Test func QUIZ_R22_no_movesTenPercentAway() {
        #expect(abs(acidity(after: .no, from: 2, wine: 8) - 1.4) < 1e-9)
    }

    @Test func QUIZ_R22_neverAboveNine() {
        #expect(acidity(after: .no, from: 9, wine: 0) == 9)
    }

    @Test func QUIZ_R22_neverBelowZero() {
        #expect(acidity(after: .no, from: 0, wine: 3) == 0)
    }

    // MARK: QUIZ-R23 · Variação

    @Test func QUIZ_R23_sameProfile_changesNothing() {
        let user = map([.acidity: 6, .oak: 2])
        for verdict in [Verdict.yes, .maybe, .no] {
            let result = MapUpdate.apply(verdict, wine: user, to: user)
            #expect(result.map == user)
            #expect(result.changes.allSatisfy { !$0.wentUp && !$0.wentDown })
        }
    }

    @Test func QUIZ_R23_reportsUpAndDown_fromFiveHundredthsOn() {
        let result = MapUpdate.apply(.yes, wine: map([.acidity: 8, .oak: 0, .fruit: 5.4]), to: map([:]))
        let byAxis = Dictionary(uniqueKeysWithValues: result.changes.map { ($0.axis, $0) })
        #expect(byAxis[.acidity]?.wentUp == true)
        #expect(byAxis[.oak]?.wentDown == true)
        #expect(byAxis[.fruit]?.wentUp == false) // +0.04
    }
}

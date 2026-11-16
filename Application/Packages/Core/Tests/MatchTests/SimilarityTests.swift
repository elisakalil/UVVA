import Core
import Testing
@testable import Match

struct SimilarityTests {
    private func map(_ value: Double) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
    }

    // MARK: QUIZ-R21 · Similaridade

    @Test func QUIZ_R21_sameProfile_isOne() {
        #expect(Similarity.between(map(4), map(4)) == 1)
    }

    @Test func QUIZ_R21_allZeroAgainstAllNine_isZero() {
        #expect(abs(Similarity.between(map(0), map(9))) < 1e-12)
    }

    @Test func QUIZ_R21_onePointApartOnEveryAxis_is78() {
        // √8 ≈ 2.83 out of 13.
        #expect(abs(Similarity.between(map(3), map(4)) - (1 - 8.0.squareRoot() / 13)) < 1e-12)
        #expect(Similarity.percent(map(3), map(4)) == 78)
    }

    @Test func QUIZ_R21_twoPointsApartOnEveryAxis_is56() {
        #expect(Similarity.percent(map(3), map(5)) == 56)
    }

    @Test func QUIZ_R21_onePointOffOnTwoAxes_is89() {
        let user = map(5)
        let wine = PalateMap(user.values.merging([.acidity: 6, .oak: 4]) { $1 })
        #expect(Similarity.percent(user, wine) == 89)
    }

    @Test func QUIZ_R21_fartherThanThirteen_isZero() {
        #expect(Similarity.between(map(1), map(6)) == 0)
        #expect(Similarity.percent(map(2), map(5)) == 35)
    }

    @Test func QUIZ_R21_aStraightLine_keepsCloseWinesApart() {
        let user = map(5)
        let percent: (Double) -> Int = { Similarity.percent(user, PalateMap(user.values.merging([.body: 5 - $0]) { $1 })) }
        #expect([1.0, 2, 3, 4, 5].map(percent) == [92, 85, 77, 69, 62])
    }

    @Test func QUIZ_R21_closerWine_scoresHigher() {
        let user = map(5)
        let near = PalateMap(user.values.merging([.acidity: 6]) { $1 })
        let far = PalateMap(user.values.merging([.acidity: 9]) { $1 })
        #expect(Similarity.between(near, user) > Similarity.between(far, user))
    }

    @Test func QUIZ_R21_sameDifferenceOnDifferentAxes_sameScore() {
        let user = map(5)
        let onAcidity = PalateMap(user.values.merging([.acidity: 7]) { $1 })
        let onOak = PalateMap(user.values.merging([.oak: 7]) { $1 })
        #expect(Similarity.between(onAcidity, user) == Similarity.between(onOak, user))
    }
}

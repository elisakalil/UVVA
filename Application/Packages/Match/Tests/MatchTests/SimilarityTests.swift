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

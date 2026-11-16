import Core
import Testing
@testable import Match

struct QuizMapBuilderTests {
    private func answers(_ value: Int, _ overrides: [PalateAxis: Int] = [:]) -> [PalateAxis: Int] {
        Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, overrides[$0] ?? value) })
    }

    private func wine(_ id: String, at positions: [PalateAxis: Double], producer: String = "P",
                      vintage: Int? = nil) -> Wine {
        Wine(id: id, name: id, producer: producer, vintage: vintage, origin: "",
             profile: PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map {
                 ($0, WineRuler.value(atPosition: positions[$0] ?? 5, on: $0))
             })))
    }

    // MARK: QUIZ-R04a · Sem vinhos, só a régua

    @Test func QUIZ_R04a_noWines_readsTheAnswersOnTheRuler() {
        let given = answers(4, [.floral: 8, .sweetness: 9])
        #expect(QuizMapBuilder.map(given, among: []) == WineRuler.map(given))
    }

    // MARK: QUIZ-R04b · Assentar entre vinhos reais

    @Test func QUIZ_R04b_settlesTowardTheClosestWines() {
        let map = QuizMapBuilder.map(answers(5), among: [wine("near", at: [.body: 6])])
        #expect(map[.body] == WineRuler.value(atPosition: 6, on: .body))
        #expect(map[.oak] == WineRuler.value(of: 5, on: .oak))
    }

    @Test func QUIZ_R04b_vintagesOfOneWine_countOnce() {
        let vintages = (2000...2030).map { wine("malbec-\($0)", at: [.fruit: 6.5], producer: "Same", vintage: $0) }
            .map { Wine(id: $0.id, name: "Malbec", producer: "Same", vintage: $0.vintage, origin: "", profile: $0.profile) }
        let other = wine("other", at: [.fruit: 3.5])
        let map = QuizMapBuilder.map(answers(5), among: vintages + [other])
        // One Malbec and the other wine, equally far: fruit lands between them, not on the Malbec.
        #expect(abs(WineRuler.position(of: map[.fruit], on: .fruit) - 5) < 1e-9)
    }

    // MARK: QUIZ-R04c · A alma

    @Test func QUIZ_R04c_anAxisStaysWithinTheBandOfItsAnswer() {
        let map = QuizMapBuilder.map(answers(5, [.floral: 8]), among: [wine("plain", at: [.floral: 2])])
        #expect(abs(WineRuler.position(of: map[.floral], on: .floral) - 6.5) < 1e-9)
    }

    @Test func QUIZ_R04c_aHighAnswer_staysAboveTheMiddle() {
        #expect(QuizMapBuilder.hold(4, near: 6) == 5.5)
        #expect(QuizMapBuilder.hold(9, near: 6) == 7.5)
    }

    @Test func QUIZ_R04c_aLowAnswer_staysBelowTheMiddle() {
        #expect(QuizMapBuilder.hold(5, near: 3) == 3.5)
        #expect(QuizMapBuilder.hold(0, near: 3) == 1.5)
    }

    @Test func QUIZ_R04c_lovingFloral_keepsFloralOnTop() {
        let wines = [wine("a", at: [.floral: 6, .acidity: 7]), wine("b", at: [.floral: 5, .acidity: 8])]
        let map = QuizMapBuilder.map(answers(4, [.floral: 9]), among: wines)
        #expect(MapReading(map: map).ranked.prefix(2).contains(.floral))
    }
}

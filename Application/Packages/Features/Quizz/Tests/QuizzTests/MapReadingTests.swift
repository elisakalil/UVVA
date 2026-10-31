import Core
import Foundation
import Testing
@testable import Quizz

struct MapReadingTests {
    let example = MapReading(map: PalateMap([.sweetness: 1, .acidity: 4, .tannin: 3, .body: 3,
                                             .fruit: 4, .floral: 2, .oak: 2, .spice: 3]))

    // MARK: QUIZ-R14, R15 · Ranking e textos

    @Test func QUIZ_R14_topThreeAndWeakest() {
        #expect(example.top3 == [.acidity, .fruit, .body])
        #expect(example.weakest == .sweetness)
    }

    @Test func QUIZ_R15_dominantPhrase() {
        #expect(example.dominantPhrase == "Acidity · Fruit · Body")
    }

    @Test func QUIZ_R15_caption() {
        #expect(example.caption == "Strongest on acidity, quietest on sweetness. The shape of what you reach for in a glass.")
    }

    @Test func QUIZ_R15_narrative_isHighTop1_highTop2_lowWeakest() {
        #expect(example.narrative == "Acidity is the first thing you notice, and it is what keeps a wine awake for you. "
            + "Ripe fruit is the point for you, not a beginner's phase to grow out of. "
            + "Sugar reads as a flaw to you, and dry means dry.")
    }

    // MARK: QUIZ-R05 · Nível exibido

    @Test func QUIZ_R05_levelIsTheRoundedIntensity() {
        #expect(MapReading.level(6.4) == 6)
        #expect(MapReading.levelWord(6) == "Quite a lot")
        #expect(MapReading.levelWord(0) == "None")
        #expect(MapReading.levelWord(9) == "As much as possible")
    }

    // MARK: QUIZ-R19, R20a · Partilha neutra

    @Test func QUIZ_R19_lovesAndNever() {
        #expect(example.loves("Elisa") == "Elisa drinks for acidity, fruit and body, in that order.")
        #expect(example.never == "Pour something built on sweetness and the glass comes back. Politely.")
    }

    @Test func QUIZ_R20a_noGenderedPronounInAnyGeneratedText() {
        let gendered: Set<String> = ["her", "she", "his", "he", "him"]
        for axis in PalateAxis.allCases {
            var values = Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 5.0) })
            values[axis] = 9
            let reading = MapReading(map: PalateMap(values))
            let text = [reading.caption, reading.narrative, reading.loves("Sam"), reading.never,
                        AxisLore.high(axis), AxisLore.low(axis)].joined(separator: " ")
            let words = Set(text.lowercased().components(separatedBy: CharacterSet.letters.inverted))
            #expect(words.isDisjoint(with: gendered), "\(axis)")
        }
    }
}

import Core
import Foundation
import Testing
@testable import Match

struct MapReadingTests {
    let example = MapReading(map: PalateMap([.sweetness: 1, .acidity: 4, .tannin: 3, .body: 3,
                                             .fruit: 4, .floral: 2, .oak: 2, .spice: 3]))
    let shaped = MapReading(map: PalateMap([.acidity: 8, .fruit: 7, .body: 6, .tannin: 5,
                                            .spice: 4, .floral: 3, .oak: 2, .sweetness: 1]))

    private func reading(_ value: Double, except: [PalateAxis: Double] = [:]) -> MapReading {
        let values = Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) })
        return MapReading(map: PalateMap(values.merging(except) { $1 }))
    }

    // MARK: QUIZ-R14, R14a · Ranking e empates

    @Test func QUIZ_R14a_tiersGroupTheSameLevel() {
        #expect(example.tiers == [[.acidity, .fruit], [.body, .tannin, .spice], [.floral, .oak], [.sweetness]])
    }

    @Test func QUIZ_R14a_leaders_neverCutATie() {
        #expect(example.leaders(3) == [.acidity, .fruit])
        #expect(shaped.leaders(3) == [.acidity, .fruit, .body])
        #expect(reading(3).leaders(3).isEmpty)
    }

    @Test func QUIZ_R14a_tiesUseTheDisplayedLevel() {
        let nearlyTied = reading(3, except: [.acidity: 7.2, .fruit: 6.8])
        #expect(nearlyTied.leaders(1).isEmpty)
        #expect(nearlyTied.dominantPhrase == "Acidity · Fruit")
        #expect(nearlyTied.loves("Elisa") == "Elisa drinks for acidity and fruit.")
    }

    @Test func QUIZ_R14a_shapes() {
        #expect(reading(3).shape == .flat(.low))
        #expect(reading(5).shape == .flat(.neutral))
        #expect(reading(7).shape == .flat(.high))
        #expect(reading(7, except: [.oak: 2]).shape == .allButOneLower(.oak))
        #expect(reading(2, except: [.acidity: 7]).shape == .allButOneHigher(.acidity))
        #expect(shaped.shape == .shaped)
    }

    // MARK: QUIZ-R15 · Textos gerados

    @Test func QUIZ_R15_shapedMap() {
        #expect(shaped.dominantPhrase == "Acidity · Fruit · Body")
        #expect(shaped.caption == "Strongest on acidity, quietest on sweetness. The shape of what you reach for in a glass.")
        #expect(shaped.narrative == "Acidity is the first thing you notice, and it is what keeps a wine awake for you. "
            + "Ripe fruit is the point for you, not a beginner's phase to grow out of. "
            + "Sugar reads as a flaw to you, and dry means dry.")
    }

    @Test func QUIZ_R15_tiedTop_namesTheWholeTie_andALowTopGetsNoHighText() {
        #expect(example.dominantPhrase == "Acidity · Fruit")
        #expect(example.caption == "Leaning most toward acidity and fruit, quietest on sweetness. The shape of what you reach for in a glass.")
        #expect(example.narrative == "Nothing on the map climbs high, so no single part of a wine has to lead. "
            + "Sugar reads as a flaw to you, and dry means dry.")
    }

    @Test func QUIZ_R15_allEqualAndLow() {
        let map = reading(3)
        #expect(map.dominantPhrase == "Quiet on every axis")
        #expect(map.caption == "Quiet on all eight axes. The shape of what you reach for in a glass.")
        #expect(map.narrative == "Every axis sits low on your map: you want a quiet wine, one that whispers instead of making a point.")
        #expect(map.highlighted.isEmpty)
    }

    @Test func QUIZ_R15_allEqualInTheMiddle() {
        let map = reading(5)
        #expect(map.dominantPhrase == "In the middle on every axis")
        #expect(map.caption == "In the middle on all eight axes. The shape of what you reach for in a glass.")
        #expect(map.narrative.hasPrefix("Every axis sits in the middle"))
    }

    @Test func QUIZ_R15_allEqualAndHigh_hasNoLowText() {
        let map = reading(7)
        #expect(map.dominantPhrase == "High on every axis")
        #expect(map.caption == "High on all eight axes. The shape of what you reach for in a glass.")
        #expect(map.narrative == "Every axis runs high on your map: you want a wine that does a lot at once, with nothing held back.")
    }

    @Test func QUIZ_R15_sevenHighOneLow() {
        let map = reading(7, except: [.oak: 2])
        #expect(map.dominantPhrase == "Everything but oak")
        #expect(map.caption == "Even on seven axes, quietest on oak. The shape of what you reach for in a glass.")
        #expect(map.narrative == "Most of the map runs high: you want a wine that does a lot at once, with no single axis in charge. "
            + "You want the grape, not the barrel.")
        #expect(map.highlighted.isEmpty)
    }

    @Test func QUIZ_R15_sevenLowOneHigh() {
        let map = reading(2, except: [.acidity: 7])
        #expect(map.dominantPhrase == "Acidity")
        #expect(map.caption == "Strongest on acidity, even on the other seven. The shape of what you reach for in a glass.")
        #expect(map.narrative == "Acidity is the first thing you notice, and it is what keeps a wine awake for you. "
            + "Most of the map stays quiet: you want restraint more than power.")
        #expect(map.highlighted == [.acidity])
    }

    @Test func QUIZ_R15_manyTiedOnALowTop_isNotStrongest() {
        let map = reading(3, except: [.spice: 2, .fruit: 0])
        #expect(map.dominantPhrase == "Quiet on most axes")
        #expect(map.caption == "Quiet on most axes, quietest on fruit. The shape of what you reach for in a glass.")
        #expect(map.narrative == "Nothing on the map climbs high, so no single part of a wine has to lead. "
            + "You look past fruit for earth, salt and stone.")
        #expect(map.loves("Elisa") == "Elisa drinks for restraint, most axes kept low.")
        #expect(map.never == "Pour something built on fruit and the glass comes back. Politely.")
    }

    @Test func QUIZ_R15_manyTiedInTheMiddle() {
        let map = reading(5, except: [.spice: 2, .fruit: 0])
        #expect(map.dominantPhrase == "In the middle on most axes")
        #expect(map.caption.hasPrefix("In the middle on most axes, quietest on fruit."))
        #expect(map.loves("Elisa") == "Elisa drinks for balance, most axes in the middle.")
    }

    @Test func QUIZ_R15_manyTiedOnAHighTop_isStrongestOnSeveral() {
        let map = reading(8, except: [.spice: 2, .fruit: 0])
        #expect(map.dominantPhrase == "Everything but spice and fruit")
        #expect(map.caption.hasPrefix("Strongest on several axes at once, quietest on fruit."))
        #expect(map.loves("Elisa") == "Elisa drinks for many things at once.")
    }

    @Test func QUIZ_R15_sevenLowOneLower_isNotEverythingBut() {
        let map = reading(3, except: [.oak: 1])
        #expect(map.dominantPhrase == "Quiet on most axes")
        #expect(map.caption.hasPrefix("Even on seven axes, quietest on oak."))
        #expect(map.loves("Elisa") == "Elisa drinks for restraint, most axes kept low.")
    }

    @Test func QUIZ_R15_oneAboveSevenLow_withALowTop_onlyLeans() {
        let map = reading(2, except: [.acidity: 4])
        #expect(map.dominantPhrase == "Acidity")
        #expect(map.caption.hasPrefix("Leaning most toward acidity, even on the other seven."))
        #expect(map.narrative.hasPrefix("Nothing on the map climbs high"))
    }

    // MARK: QUIZ-R05 · Nível exibido

    @Test func QUIZ_R05_levelIsTheRoundedIntensity() {
        #expect(MapReading.level(6.4) == 6)
        #expect(MapReading.levelWord(6) == "Quite a lot")
        #expect(MapReading.levelWord(0) == "None")
        #expect(MapReading.levelWord(9) == "As much as possible")
    }

    @Test func QUIZ_R14a_fiveIsNeitherHighNorLow() {
        #expect(AxisTone(4.4) == .low)
        #expect(AxisTone(5) == .neutral)
        #expect(AxisTone(5.4) == .neutral)
        #expect(AxisTone(5.6) == .high)
    }

    // MARK: QUIZ-R19, R20a · Partilha neutra

    @Test func QUIZ_R19_lovesAndNever() {
        #expect(shaped.loves("Elisa") == "Elisa drinks for acidity, fruit and body, in that order.")
        #expect(shaped.never == "Pour something built on sweetness and the glass comes back. Politely.")
        #expect(shaped.signature == "ACIDITY · FRUIT · BODY")
    }

    @Test func QUIZ_R19_lovesAndNever_byShape() {
        #expect(reading(3).loves("Elisa") == "Elisa drinks for restraint, every axis kept low.")
        #expect(reading(3).never == "Pour something loud and the glass comes back. Politely.")
        #expect(reading(7).never == "Pour almost anything: nothing on this map sends a glass back.")
        #expect(reading(7, except: [.oak: 2]).loves("Elisa") == "Elisa drinks for everything but oak.")
        #expect(reading(7, except: [.oak: 2]).never == "Pour something built on oak and the glass comes back. Politely.")
        #expect(reading(2, except: [.acidity: 7]).lovesWithoutName == "Drinks for acidity above all.")
        #expect(reading(2, except: [.acidity: 7]).never == "Pour something loud and the glass comes back. Politely.")
    }

    @Test func QUIZ_R20a_noGenderedPronounInAnyGeneratedText() {
        let gendered: Set<String> = ["her", "she", "his", "he", "him"]
        var readings = [reading(3), reading(5), reading(7), example, shaped]
        for axis in PalateAxis.allCases {
            readings += [reading(5, except: [axis: 9]), reading(7, except: [axis: 2]), reading(2, except: [axis: 7]),
                         reading(3, except: [axis: 1]), reading(2, except: [axis: 4])]
        }
        for reading in readings {
            let text = [reading.caption, reading.narrative, reading.loves("Sam"), reading.never, reading.dominantPhrase]
                .joined(separator: " ")
            let words = Set(text.lowercased().components(separatedBy: CharacterSet.letters.inverted))
            #expect(words.isDisjoint(with: gendered), "\(reading.map)")
        }
        for axis in PalateAxis.allCases {
            let words = Set((AxisLore.high(axis) + " " + AxisLore.low(axis)).lowercased()
                .components(separatedBy: CharacterSet.letters.inverted))
            #expect(words.isDisjoint(with: gendered), "\(axis)")
        }
    }
}

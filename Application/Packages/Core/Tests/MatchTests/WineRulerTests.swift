import Core
import Testing
@testable import Match

private extension Double {
    var asLevel: Int { Int(self) }
}

struct WineRulerTests {
    // MARK: QUIZ-R04a · A régua

    @Test func QUIZ_R04a_everyAxisRises_andStaysOnTheScale() {
        for axis in PalateAxis.allCases {
            let steps = (0...9).map { WineRuler.value(of: $0, on: axis) }
            #expect(zip(steps, steps.dropFirst()).allSatisfy { $0 <= $1 })
            #expect(steps.allSatisfy { PalateMap.range.contains($0) })
        }
    }

    @Test func QUIZ_R04a_sweetness_followsTheHandTable() {
        #expect((0...9).map { WineRuler.value(of: $0, on: .sweetness) } == [1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 3.0, 5.0, 7.0, 8.5])
    }

    @Test func QUIZ_R04a_anAnswerReadsBackAsItsPosition() {
        for axis in PalateAxis.allCases where axis != .sweetness {
            for answer in 0...9 {
                #expect(abs(WineRuler.position(of: WineRuler.value(of: answer, on: axis), on: axis) - Double(answer)) < 1e-9)
            }
        }
    }

    @Test func QUIZ_R04a_aDryWine_readsLowOnSweetness_andBoneDryReadsZero() {
        #expect(WineRuler.position(of: 1.0, on: .sweetness) == 1.5)
        #expect(WineRuler.position(of: 0.5, on: .sweetness) == 0)
        #expect(WineRuler.position(of: 2.0, on: .sweetness) == 5)
    }

    @Test func QUIZ_R04a_sweetness_hasNoJumpAboveDry() {
        let dry = WineRuler.position(of: 1.0, on: .sweetness)
        let barely = WineRuler.position(of: 1.01, on: .sweetness)
        #expect(barely > dry && barely - dry < 0.1)
        #expect(WineRuler.value(atPosition: 0.5, on: .sweetness) == 1.0)
    }

    @Test func QUIZ_R05_everyLevelOfEveryAxis_hasItsOwnDescription() {
        for axis in PalateAxis.allCases {
            #expect(AxisLevels.words(axis).count == 10)
        }
        #expect(AxisLevels.word(WineRuler.positions(of: PalateMap([.sweetness: 1.0]))[.sweetness].rounded().asLevel,
                                on: .sweetness) == "Dry")
        #expect(AxisLevels.word(9, on: .sweetness) == "Lusciously sweet")
    }

    @Test func QUIZ_R04a_positionsBetweenAnswers_areAStraightLine() {
        #expect(WineRuler.value(atPosition: 8.5, on: .floral) == 6.25)
        #expect(abs(WineRuler.position(of: 6.25, on: .floral) - 8.5) < 1e-9)
        #expect(WineRuler.position(of: 9, on: .floral) == 9)
    }

    @Test func QUIZ_R05_theRadar_showsThePosition() {
        let map = WineRuler.map(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, 7) }))
        let chart = map.chartValues
        for (index, axis) in PalateAxis.allCases.enumerated() where axis != .sweetness {
            #expect(abs(chart[index] - 7.0 / 9) < 1e-9)
        }
    }
}

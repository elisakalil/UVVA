import Core
import Testing
@testable import Learn

struct LessonGraderTests {
    let selectMultiple = LessonStep.selectMultiple(prompt: "Which?", options: ["A", "B", "C", "D"], answers: [0, 1, 3], explanation: "ABD.")

    // MARK: LEARN-R17 · Responder e verificar

    @Test func LEARN_R17_selectMultiple_missingOne_isNotQuite() {
        #expect(!LessonGrader.isCorrect(selectMultiple, .options([0, 1])))
    }

    @Test func LEARN_R17_selectMultiple_exactSet_isCorrect() {
        #expect(LessonGrader.isCorrect(selectMultiple, .options([0, 1, 3])))
    }

    @Test func LEARN_R17_selectMultiple_oneTooMany_isNotQuite() {
        #expect(!LessonGrader.isCorrect(selectMultiple, .options([0, 1, 2, 3])))
    }

    @Test func LEARN_R17_fillBlank_withoutAWord_cannotCheck() {
        let step = LessonStep.fillBlank(prompt: "Juice is ____.", options: ["must", "lees"], answer: "must", explanation: "")
        #expect(!LessonGrader.canCheck(step, StepDraft()))
        #expect(LessonGrader.canCheck(step, StepDraft(word: "lees")))
    }

    @Test func LEARN_R17_ordering_canAlwaysCheck() {
        #expect(LessonGrader.canCheck(.ordering(prompt: "", items: ["A", "B"], explanation: ""), StepDraft()))
    }

    @Test func LEARN_R17_trueFalse_andMultipleChoice() {
        #expect(LessonGrader.isCorrect(.trueFalse(prompt: "", answer: false, explanation: ""), .trueFalse(false)))
        #expect(!LessonGrader.isCorrect(.multipleChoice(prompt: "", options: ["A", "B"], answer: 1, explanation: ""), .options([0])))
    }

    // MARK: LEARN-R17a · Feedback de ordering

    @Test func LEARN_R17a_wrongOrder_startsWithTheCorrectOrder() {
        let step = LessonStep.ordering(prompt: "", items: ["Harvest", "Press", "Ferment"], explanation: "Picked first.")
        #expect(LessonGrader.explanation(step, .order([1, 0, 2])) == "Correct order: 1. Harvest  2. Press  3. Ferment. Picked first.")
        #expect(LessonGrader.explanation(step, .order([0, 1, 2])) == "Picked first.")
    }

    // MARK: LEARN-R17b · Ordem embaralhada

    @Test func LEARN_R17b_fourItems_neverStartInTheRightOrder() {
        for step in 0..<500 {
            let order = SeededShuffle.order(count: 4, seed: SeededShuffle.seed(lessonID: "path-01-l01", step: step))
            #expect(order != [0, 1, 2, 3])
            #expect(order.sorted() == [0, 1, 2, 3])
        }
    }

    @Test func LEARN_R17b_sameStep_sameOrderEveryTime() {
        let seed = SeededShuffle.seed(lessonID: "grape-pinot-noir-l02", step: 4)
        #expect(SeededShuffle.order(count: 5, seed: seed) == SeededShuffle.order(count: 5, seed: seed))
    }

    // MARK: LEARN-R18 · matchPairs

    @Test func LEARN_R18_fivePairsOneMiss_saysOneWrongTry() {
        let pairs = (1...5).map { MatchPair(left: "L\($0)", right: "R\($0)") }
        let step = LessonStep.matchPairs(prompt: "", pairs: pairs, explanation: nil)
        #expect(LessonGrader.explanation(step, .pairs(misses: 1)) == "All 5 pairs matched, with 1 wrong try.")
        #expect(!LessonGrader.isCorrect(step, .pairs(misses: 1)))
        #expect(LessonGrader.explanation(step, .pairs(misses: 0)) == "All 5 pairs matched on the first try.")
    }
}

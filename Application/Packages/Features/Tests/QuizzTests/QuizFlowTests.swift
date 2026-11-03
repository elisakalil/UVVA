import Core
import Testing
@testable import Quizz

struct QuizFlowTests {
    private func flow(answering count: Int, with position: Int = 4) -> QuizFlow {
        var flow = QuizFlow()
        flow.start()
        for _ in 0..<count {
            flow.select(position)
            flow.next()
        }
        return flow
    }

    // MARK: QUIZ-R07 · Uma pergunta por eixo

    @Test func QUIZ_R07_firstReading_isSweetness() {
        let flow = flow(answering: 0)
        #expect(flow.step == .reading(0))
        #expect(flow.axis == .sweetness)
    }

    @Test func QUIZ_R07_readingsFollowTheQuestionOrder() {
        var flow = QuizFlow()
        flow.start()
        var axes: [PalateAxis] = []
        for _ in 0..<8 {
            axes.append(flow.axis!)
            flow.select(1)
            flow.next()
        }
        #expect(axes == [.sweetness, .acidity, .tannin, .body, .fruit, .floral, .oak, .spice])
    }

    // MARK: QUIZ-R09 · Change question

    @Test func QUIZ_R09_changeQuestion_keepsThePosition_andLoopsThroughThreeVersions() {
        var flow = flow(answering: 0)
        flow.select(6)
        flow.changeQuestion()
        #expect(flow.version(of: .sweetness) == 2)
        #expect(flow.selection == 6)
        flow.changeQuestion()
        flow.changeQuestion()
        #expect(flow.version(of: .sweetness) == 1)
    }

    // MARK: QUIZ-R10, R11 · Responder e avançar

    @Test func QUIZ_R10_newReading_startsEmpty_andCannotAdvance() {
        let flow = flow(answering: 0)
        #expect(flow.selection == nil)
        #expect(!flow.canAdvance)
    }

    @Test func QUIZ_R11_nextWithoutAnswer_staysPut() {
        var flow = flow(answering: 0)
        flow.next()
        #expect(flow.step == .reading(0))
    }

    @Test func QUIZ_R11_lastReading_drawsTheMap() {
        var flow = flow(answering: 7)
        #expect(flow.isLastReading)
        flow.select(3)
        flow.next()
        #expect(flow.step == .result)
        #expect(flow.map != nil)
    }

    @Test func QUIZ_R10_positionsOutsideTheBar_areIgnored() {
        var flow = flow(answering: 0)
        flow.select(10)
        #expect(flow.selection == nil)
    }

    // MARK: QUIZ-R12 · Voltar

    @Test func QUIZ_R12_back_keepsAnswerAndVersion() {
        var flow = flow(answering: 2)
        flow.select(4) // reading 3 (tannin)
        flow.changeQuestion()
        flow.next()
        flow.back()
        #expect(flow.axis == .tannin)
        #expect(flow.selection == 4)
        #expect(flow.version(of: .tannin) == 2)
    }

    @Test func QUIZ_R12_backFromTheFirstReading_opensTheIntro() {
        var flow = flow(answering: 0)
        flow.back()
        #expect(flow.step == .intro)
    }

    // MARK: QUIZ-R04 · Intensidade

    @Test func QUIZ_R04_mapKeepsEachPositionAsItIs() {
        var flow = QuizFlow()
        flow.start()
        for position in [1, 6, 3, 3, 4, 2, 2, 3] {
            flow.select(position)
            flow.next()
        }
        #expect(flow.map?[.acidity] == 6)
        #expect(flow.map?[.sweetness] == 1)
    }

    // MARK: QUIZ-R18 · Read it again

    @Test func QUIZ_R18_readAgain_emptiesEveryBar_andOpensReadingOne() {
        var flow = flow(answering: 8)
        flow.readAgain()
        #expect(flow.step == .reading(0))
        #expect(flow.selection == nil)
        #expect(flow.map == nil)
    }
}

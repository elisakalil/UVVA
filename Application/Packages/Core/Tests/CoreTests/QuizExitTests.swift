import Testing
@testable import Core

struct QuizExitTests {
    // MARK: QUIZ-R25 · Saídas

    @Test func QUIZ_R25_firstMap_goesHomeWithTheTour() {
        #expect(QuizExit(for: .firstMap) == .homeWithTour)
    }

    @Test func QUIZ_R25_redo_goesToYouMap() {
        #expect(QuizExit(for: .redo) == .youMap)
    }
}

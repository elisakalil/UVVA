import Combine
import Core
import Testing
@testable import Quizz

@MainActor
struct QuizViewModelTests {
    let maps = PalateMapRepositorySpy()

    private func makeViewModel(entry: QuizEntry = .firstMap, maps: PalateMapRepositorySpy? = nil,
                               onExit: @escaping (QuizExit) -> Void = { _ in }) async -> QuizViewModel {
        let viewModel = QuizFactory(questions: QuestionRepositoryStub(), maps: maps ?? self.maps)
            .makeViewModel(entry: entry, firstName: "Elisa", coordinator: QuizCoordinator(entry: entry, onExit: onExit))
        await viewModel.load()
        return viewModel
    }

    private func answerAll(_ viewModel: QuizViewModel, with position: Int = 4) {
        viewModel.start()
        for _ in 0..<8 {
            viewModel.select(position)
            viewModel.next()
        }
    }

    // MARK: QUIZ-R06 · Intro

    @Test func QUIZ_R06_intro_greetsByFirstName() async {
        let viewModel = await makeViewModel()
        guard case let .intro(model) = viewModel.uiModel.screen else { Issue.record("not intro"); return }
        #expect(model.greeting == "Welcome, Elisa")
        #expect(model.button == "Read my palate")
        #expect(!model.canLeave)
    }

    // MARK: QUIZ-R07, R09, R11 · Leitura

    @Test func QUIZ_R07_firstReading_showsCounterAndAxis() async {
        let viewModel = await makeViewModel()
        viewModel.start()
        guard case let .reading(model) = viewModel.uiModel.screen else { Issue.record("not reading"); return }
        #expect(model.counter == "1 of 8")
        #expect(model.answer == nil)
        #expect(!model.canAdvance)
        #expect(model.button == "Next")
    }

    @Test func QUIZ_R09_changeQuestion_showsTheWordOfTheNewVersionAtTheSamePosition() async {
        let viewModel = await makeViewModel()
        viewModel.start()
        viewModel.select(6)
        viewModel.changeQuestion()
        guard case let .reading(model) = viewModel.uiModel.screen else { Issue.record("not reading"); return }
        #expect(model.prompt == "sweetness v2?")
        #expect(model.answer == "sweetness v2 #6")
    }

    @Test func QUIZ_R11_lastReading_saysDrawTheMap() async {
        let viewModel = await makeViewModel()
        viewModel.start()
        for _ in 0..<7 {
            viewModel.select(2)
            viewModel.next()
        }
        guard case let .reading(model) = viewModel.uiModel.screen else { Issue.record("not reading"); return }
        #expect(model.button == "Draw the map")
    }

    // MARK: QUIZ-R18 · Keep e Read it again

    @Test func QUIZ_R18_readAgain_savesNothing() async {
        let viewModel = await makeViewModel()
        answerAll(viewModel)
        viewModel.readAgain()
        #expect(maps.savedMaps.isEmpty)
        guard case let .reading(model) = viewModel.uiModel.screen else { Issue.record("not reading"); return }
        #expect(model.index == 0)
        #expect(model.selection == nil)
    }

    @Test func QUIZ_R18_keep_savesTheMap_andOpensTheShareSheet() async {
        let viewModel = await makeViewModel()
        answerAll(viewModel, with: 5)
        await viewModel.keep()
        #expect(maps.savedMaps.count == 1)
        #expect(maps.savedMaps.first?[.oak] == 5)
        guard case let .share(model) = viewModel.uiModel.screen else { Issue.record("not share"); return }
        #expect(model.loves.hasPrefix("Elisa drinks for"))
    }

    @Test func keep_whenSavingFails_staysOnTheMapWithAMessage() async {
        let failing = PalateMapRepositorySpy(fails: true)
        let viewModel = await makeViewModel(maps: failing)
        answerAll(viewModel)
        await viewModel.keep()
        guard case let .result(model) = viewModel.uiModel.screen else { Issue.record("not result"); return }
        #expect(model.failedToSave)
    }

    // MARK: QUIZ-R25, R26 · Saídas

    @Test func QUIZ_R25_firstMap_finishGoesHomeWithTheTour() async {
        var exit: QuizExit?
        let viewModel = await makeViewModel(entry: .firstMap) { exit = $0 }
        answerAll(viewModel)
        await viewModel.keep()
        viewModel.finish()
        #expect(exit == .homeWithTour)
    }

    @Test func QUIZ_R25_redo_finishGoesToYouMap() async {
        var exit: QuizExit?
        let viewModel = await makeViewModel(entry: .redo) { exit = $0 }
        answerAll(viewModel)
        await viewModel.keep()
        viewModel.finish()
        #expect(exit == .youMap)
    }

    @Test func QUIZ_R26_firstMap_hasNoWayOut() async {
        var exit: QuizExit?
        let viewModel = await makeViewModel(entry: .firstMap) { exit = $0 }
        viewModel.leave()
        #expect(exit == nil)
    }

    @Test func QUIZ_R26_redo_leavingFromTheIntro_keepsTheMap() async {
        var exit: QuizExit?
        let viewModel = await makeViewModel(entry: .redo) { exit = $0 }
        viewModel.leave()
        #expect(exit == .youMap)
        #expect(maps.savedMaps.isEmpty)
    }

    @Test func uiModel_publishesReadingSelectionAndAdvance() async {
        let model = await makeViewModel()
        var screens: [QuizScreen] = []
        let subscription = model.$uiModel.sink { screens.append($0.screen) }
        defer { subscription.cancel() }
        model.start()
        model.select(4)
        model.next()
        #expect(screens.contains { screen in
            guard case let .reading(reading) = screen else { return false }
            return reading.index == 0 && reading.selection == 4 && reading.canAdvance
        })
        guard case let .reading(reading) = screens.last else {
            Issue.record("Expected reading"); return
        }
        #expect(reading.index == 1)
        #expect(reading.selection == nil)
    }

}

import Combine
import Core
import Testing
@testable import Home

struct GuidedTourTests {
    // MARK: HOME-R29 · Quando aparece

    @Test func HOME_R29_firstMapAndNotSeen_showsTheTour() {
        #expect(GuidedTour.shouldShow(quizExit: .homeWithTour, seenTours: []))
    }

    @Test func HOME_R29_redo_doesNotShowTheTour() {
        #expect(!GuidedTour.shouldShow(quizExit: .youMap, seenTours: []))
    }

    @Test func HOME_R29_alreadySeen_doesNotShowTheTour() {
        #expect(!GuidedTour.shouldShow(quizExit: .homeWithTour, seenTours: ["home"]))
    }

    @Test func HOME_R29_withoutTheQuiz_doesNotShowTheTour() {
        #expect(!GuidedTour.shouldShow(quizExit: nil, seenTours: []))
    }

    // MARK: HOME-R30, R32 · Navegação

    @Test func HOME_R30_startsOnTheIntro_andShowMeOpensStepOne() {
        var tour = GuidedTour()
        #expect(tour.step == 0)
        tour.next()
        #expect(tour.step == 1)
    }

    @Test func HOME_R32_backFromStepOne_opensTheIntro() {
        var tour = GuidedTour()
        tour.next()
        tour.back()
        #expect(tour.step == 0)
    }

    @Test func HOME_R32_dots_openTheirStep() {
        var tour = GuidedTour()
        tour.pick(4)
        tour.pick(2)
        #expect(tour.step == 2)
        tour.pick(6)
        #expect(tour.step == 2)
    }

    // MARK: HOME-R33 · Fim

    @Test func HOME_R33_nextOnStepFive_finishes() {
        var tour = GuidedTour()
        tour.pick(5)
        #expect(!tour.isFinished)
        tour.next()
        #expect(tour.isFinished)
    }

    @MainActor
    @Test func HOME_R32_R33_labelsAndFinish() {
        var finished = false
        let viewModel = GuidedTourViewModel(firstName: "Elisa") { finished = true }
        #expect(viewModel.uiModel.counter == "Tour")
        viewModel.next()
        #expect(viewModel.uiModel.counter == "1 of 5")
        #expect(viewModel.uiModel.nextTitle == "Next")
        viewModel.pick(5)
        #expect(viewModel.uiModel.nextTitle == "Start")
        viewModel.next()
        #expect(finished)
    }

    @MainActor
    @Test func HOME_R31_fiveSteps_heroFirst_scanSecond_andTheTabsComeLast() {
        let viewModel = GuidedTourViewModel(firstName: "Elisa") {}
        #expect(GuidedTour.stepCount == 5)
        viewModel.pick(1)
        #expect(viewModel.uiModel.current?.target == HomeSpotlightID.today)
        viewModel.pick(2)
        #expect(viewModel.uiModel.current?.target == HomeSpotlightID.scan)
        viewModel.pick(5)
        #expect(viewModel.uiModel.current?.target == "tab.friends")
    }

    @MainActor
    @Test func uiModel_publishesSpotlightChangesAndCompletion() {
        var finished = false
        let model = GuidedTourViewModel(firstName: "Elisa") { finished = true }
        var presentations: [GuidedTourUIModel] = []
        let subscription = model.$uiModel.sink { presentations.append($0) }
        defer { subscription.cancel() }
        model.next()
        model.pick(2)
        #expect(presentations.last?.current?.target == HomeSpotlightID.scan)
        model.back()
        #expect(presentations.last?.step == 1)
        model.pick(5)
        model.next()
        #expect(presentations.first?.counter == "Tour")
        #expect(presentations.last?.isFinished == true)
        #expect(finished)
    }

    @MainActor
    @Test func completedTour_ignoresFurtherActionsAndFinishesOnce() {
        var completions = 0
        let model = GuidedTourViewModel(firstName: "Elisa") { completions += 1 }
        model.pick(5)
        model.next()
        model.next()
        model.back()
        model.pick(2)
        model.next()
        #expect(completions == 1)
        #expect(model.uiModel.isFinished)
        #expect(model.uiModel.step == 5)
    }

}

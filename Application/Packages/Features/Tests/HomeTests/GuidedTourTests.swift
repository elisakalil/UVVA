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
        tour.pick(9)
        #expect(tour.step == 2)
    }

    // MARK: HOME-R33 · Fim

    @Test func HOME_R33_nextOnStepSix_finishes() {
        var tour = GuidedTour()
        tour.pick(6)
        #expect(!tour.isFinished)
        tour.next()
        #expect(tour.isFinished)
    }

    @MainActor
    @Test func HOME_R32_R33_labelsAndFinish() {
        var finished = false
        let viewModel = GuidedTourViewModel(firstName: "Elisa") { finished = true }
        #expect(viewModel.counter == "Tour")
        viewModel.next()
        #expect(viewModel.counter == "1 of 6")
        #expect(viewModel.nextTitle == "Next")
        viewModel.pick(6)
        #expect(viewModel.nextTitle == "Start")
        viewModel.next()
        #expect(finished)
    }

    @MainActor
    @Test func HOME_R31_stepTwo_pointsAtChooseYourWine_andTheTabsComeLast() {
        let viewModel = GuidedTourViewModel(firstName: "Elisa") {}
        viewModel.pick(2)
        #expect(viewModel.current?.target == HomeSpotlightModel.chooseYourWine)
        viewModel.pick(6)
        #expect(viewModel.current?.target == "tab.friends")
    }
}

import Core
import Foundation
import Testing
@testable import Learn

@MainActor
struct LessonPlayerViewModelTests {
    let course = Fixture.course("grape-tannat", lessons: 2)
    let learning = LearningSpy()

    func player(_ lessonIndex: Int = 0, progress: LessonProgress? = nil, startStep: Int? = nil,
                onExit: @escaping (LessonPlayerViewModel.Exit) -> Void = { _ in }) -> LessonPlayerViewModel {
        let summary = course.lessons[lessonIndex]
        return LessonPlayerViewModel(course: course, lesson: Lesson(summary: summary, steps: Fixture.steps(review: summary.isReview)),
                                     progress: progress, startStep: startStep, learning: learning, now: { Fixture.day },
                                     pickToast: { _ in 0 }, onCompleted: { nil }, onExit: onExit)
    }

    /// Plays to the Summary, answering the two questions; `right` decides how.
    func playToSummary(_ player: LessonPlayerViewModel, right: Bool) {
        player.begin()
        player.primary()                    // concept
        player.primary()                    // concept
        player.tapOption(right ? 2 : 0)     // multipleChoice, answer 2
        player.primary()                    // Check
        player.primary()                    // Continue
        player.primary()                    // tip
        player.tapOption(right ? 0 : 1)     // trueFalse, answer True
        player.primary()                    // Check
        player.primary()                    // Continue, onto the Summary
    }

    // MARK: LEARN-R12 · Capa

    @Test func LEARN_R12_cover_showsTheLessonAndItsObjectives() {
        let cover = player(1).cover
        #expect(cover.number == "02")
        #expect(cover.xp == "15")
        #expect(cover.steps == "6")
        #expect(cover.showsReviewPrevious)
        #expect(!player(0).cover.showsReviewPrevious)
    }

    // MARK: LEARN-R14 · Sair e retomar

    @Test func LEARN_R14_leavingAtStepFive_savesTheStepAndAnswers() async {
        let player = player()
        player.begin()
        player.primary()
        player.primary()
        player.tapOption(2)
        player.primary()
        player.primary()
        player.primary()
        player.close()
        await player.flush()
        let saved = learning.saved["grape-tannat-l01"]
        #expect(saved?.currentStep == 4)
        #expect(saved?.answers == [2: .options([2])])
        #expect(saved?.isCompleted == false)
    }

    @Test func LEARN_R14_reopened_startsAtTheSavedStepWithItsAnswers() {
        let saved = LessonProgress(lessonID: "grape-tannat-l01", courseID: course.id, currentStep: 4,
                                   answers: [2: .options([0])], lastOpenedAt: Fixture.day)
        let player = player(progress: saved, startStep: 4)
        #expect(player.stepIndex == 4)
        #expect(player.draft(2).isChecked)
    }

    // MARK: LEARN-R13 · Progresso

    @Test func LEARN_R13_header_countsTheStepsUpToTheCurrentOne() {
        let player = player()
        player.begin()
        player.primary()
        #expect(player.header.current == 1)
        #expect(player.header.counter == "02 / 06")
    }

    // MARK: LEARN-R17 · Errar não impede avançar

    @Test func LEARN_R17_wrongAnswer_continueMovesOn() {
        let player = player()
        player.begin()
        player.primary()
        player.primary()
        #expect(player.footer == .button(title: "Check", isEnabled: false))
        player.tapOption(0)
        player.primary()
        guard case let .feedback(feedback) = player.footer else { Issue.record("No feedback"); return }
        #expect(!feedback.isCorrect)
        #expect(feedback.title == "Not quite")
        player.tapOption(2) // locked after Check
        #expect(player.draft(2).selection == [0])
        player.primary()
        #expect(player.stepIndex == 3)
    }

    // MARK: LEARN-R19 · Resumo

    @Test func LEARN_R19_summary_countsRightAnswersAndListsTheMissed() {
        let player = player()
        player.begin()
        player.primary()
        player.primary()
        player.tapOption(0)                 // wrong
        player.primary()
        player.primary()
        player.primary()
        player.tapOption(0)                 // right
        player.primary()
        player.primary()
        guard case let .summary(summary) = player.stepModel else { Issue.record("Not on the Summary"); return }
        #expect(summary.score == "1/2")
        #expect(summary.missed == ["Which?"])
        #expect(summary.xp == "+15 XP")
        #expect(summary.toast == "Santé")
        #expect(summary.nextTitle == "Lesson 2")
        #expect(player.footer == .button(title: "Next lesson", isEnabled: true))
    }

    @Test func LEARN_R19_lastLesson_buttonSaysFinishModule() {
        let player = player(1)
        player.begin()
        for _ in 0..<12 where player.stepIndex != 5 {
            if case .button(_, false) = player.footer, let index = player.stepIndex {
                switch player.lesson.steps[index] {
                case .fillBlank: player.tapWord("must")
                default: player.tapOption(0)
                }
            }
            player.primary()
        }
        #expect(player.stepIndex == 5)
        #expect(player.footer == .button(title: "Finish module", isEnabled: true))
    }

    // MARK: LEARN-R21, SHARED-R15 · XP e conclusão

    @Test func LEARN_R21_reachingTheSummaryWithNoRightAnswers_earns15XP() async {
        let player = player()
        playToSummary(player, right: false)
        await player.flush()
        let saved = learning.saved["grape-tannat-l01"]
        #expect(saved?.completedAt == Fixture.day)
        #expect(saved?.xp == 15)
    }

    // MARK: LEARN-R19a · Revisão

    @Test func LEARN_R19a_reviewingACompletedLesson_savesNothingAndGivesNoXP() async {
        let done = LessonProgress(lessonID: "grape-tannat-l01", courseID: course.id, currentStep: 5,
                                  completedAt: Fixture.day.addingTimeInterval(-86_400), lastOpenedAt: Fixture.day, xp: 15)
        let player = player(progress: done)
        #expect(player.isReview)
        playToSummary(player, right: true)
        await player.flush()
        #expect(learning.saved.isEmpty)
        guard case let .summary(summary) = player.stepModel else { Issue.record("Not on the Summary"); return }
        #expect(summary.xp == "Reviewed")
    }

    @Test func reviewPrevious_opensTheLessonBefore() {
        var exits: [LessonPlayerViewModel.Exit] = []
        player(1) { exits.append($0) }.reviewPrevious()
        #expect(exits == [.open(course.lessons[0])])
    }

    // MARK: LEARN-R18 · matchPairs

    @Test func LEARN_R18_wrongPair_countsAndShowsNotAPair() {
        let pairs = [MatchPair(left: "A", right: "1"), MatchPair(left: "B", right: "2")]
        let summary = course.lessons[0]
        let player = LessonPlayerViewModel(
            course: course, lesson: Lesson(summary: summary, steps: [.matchPairs(prompt: "Match", pairs: pairs, explanation: nil),
                                                                    .summary(title: "", points: [])]),
            progress: nil, startStep: 0, learning: learning, onCompleted: { nil }, onExit: { _ in })
        player.tapLeft(0)
        player.tapRight(1)
        guard case let .matchPairs(model) = player.stepModel else { Issue.record("Not matchPairs"); return }
        #expect(model.status == "Not a pair. Try again.")
        player.tapLeft(0)
        player.tapRight(0)
        player.tapLeft(1)
        player.tapRight(1)
        guard case let .feedback(feedback) = player.footer else { Issue.record("No feedback"); return }
        #expect(feedback.text == "All 2 pairs matched, with 1 wrong try.")
        #expect(!feedback.isCorrect)
    }
}

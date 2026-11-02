import Core
import Foundation
import Testing

struct CourseRulesTests {
    let course = Course(id: "grape-tannat", kind: .grape, order: 1, title: "Tannat", about: "",
                        lessons: (1...5).map { n in
                            LessonSummary(id: "grape-tannat-l0\(n)", courseID: "grape-tannat", order: n, title: "Lesson \(n)",
                                          subtitle: "", xp: 15, minutes: 3, isReview: n == 5, objectives: [])
                        })
    let day = Date(timeIntervalSince1970: 1_800_000_000)

    func opened(_ n: Int, step: Int = 0, completed: Bool = false, at date: Date? = nil) -> (String, LessonProgress) {
        let id = "grape-tannat-l0\(n)"
        return (id, LessonProgress(lessonID: id, courseID: course.id, currentStep: step,
                                   completedAt: completed ? day : nil, lastOpenedAt: date ?? day, xp: completed ? 15 : 0))
    }

    // MARK: LEARN-R02 · Estado de um curso

    @Test func LEARN_R02_noLessonOpened_isNotStarted() {
        #expect(CourseRules.state(of: course, progress: [:]) == .notStarted)
    }

    @Test func LEARN_R02_lessonOneAtStepTwo_isInProgress() {
        #expect(CourseRules.state(of: course, progress: Dictionary(uniqueKeysWithValues: [opened(1, step: 1)])) == .inProgress)
    }

    @Test func LEARN_R02_allFiveCompleted_isDone() {
        let all = Dictionary(uniqueKeysWithValues: (1...5).map { opened($0, completed: true) })
        #expect(CourseRules.state(of: course, progress: all) == .done)
    }

    @Test func LEARN_R20_courseXP_is15PerLesson() {
        #expect(course.xp == 75)
    }

    // MARK: LEARN-R11 · Rótulo e destino

    @Test func LEARN_R11_notStarted_opensLessonOneCover() {
        #expect(CourseRules.entry(for: course, progress: [:]) == CourseEntry(lessonID: "grape-tannat-l01", step: nil))
    }

    @Test func LEARN_R11_twoDoneThirdAtStepFour_opensLessonThreeAtStepFour() {
        let progress = Dictionary(uniqueKeysWithValues: [opened(1, completed: true), opened(2, completed: true), opened(3, step: 3)])
        #expect(CourseRules.entry(for: course, progress: progress) == CourseEntry(lessonID: "grape-tannat-l03", step: 3))
    }

    @Test func LEARN_R11_nextLessonNeverOpened_opensItsCover() {
        let progress = Dictionary(uniqueKeysWithValues: [opened(1, completed: true)])
        #expect(CourseRules.entry(for: course, progress: progress) == CourseEntry(lessonID: "grape-tannat-l02", step: nil))
    }

    @Test func LEARN_R11_done_opensLessonOneCoverToReview() {
        let all = Dictionary(uniqueKeysWithValues: (1...5).map { opened($0, completed: true) })
        #expect(CourseRules.entry(for: course, progress: all) == CourseEntry(lessonID: "grape-tannat-l01", step: nil))
    }

    // MARK: SHARED-R17 · Ponto de retomada

    @Test func SHARED_R17_summary_pointsAtTheLessonAndStepToResume() {
        let later = day.addingTimeInterval(60)
        let progress = Dictionary(uniqueKeysWithValues: [opened(1, completed: true), opened(2, step: 4, at: later)])
        let summary = CourseRules.summary(of: course, progress: progress)
        #expect(summary.isInProgress)
        #expect(summary.completedLessons == 1)
        #expect(summary.lastOpenedAt == later)
        #expect(summary.current == LessonRef(number: 2, title: "Lesson 2", step: 5))
    }

    @Test func courseKind_readsTheIdPrefix() {
        #expect(CourseKind(courseID: "region-pt-douro") == .region)
        #expect(CourseKind(courseID: "path-01") == .path)
        #expect(CourseKind(courseID: "other") == nil)
    }
}

import Core
import Foundation
import Testing

struct CourseRulesTests {
    let course = Course(id: "region-test", kind: .region, order: 1, title: "Region", about: "",
        lessons: (1...6).map { n in
            LessonSummary(id: "region-test-l0\(n)", courseID: "region-test", order: n,
                title: "Lesson \(n)", subtitle: "", xp: 15, minutes: 3, isReview: n == 6, objectives: [])
        })
    let day = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func stateZero_opensFirstLesson() {
        let module = ModuleProgress(courseID: course.id)
        #expect(CourseRules.entry(for: course, module: module, progress: [:])?.lessonID == course.lessons[0].id)
        #expect(CourseRules.state(of: course, module: module) == .notStarted)
    }

    @Test func stateOne_opensSecondLesson() {
        let module = ModuleProgress(courseID: course.id, state: 1, lastOpenedAt: day)
        #expect(CourseRules.entry(for: course, module: module, progress: [:])?.lessonID == course.lessons[1].id)
    }

    @Test func everyState_opensStatePlusOne() {
        for state in 0..<6 {
            let module = ModuleProgress(courseID: course.id, state: state)
            #expect(CourseRules.entry(for: course, module: module, progress: [:])?.lessonID == course.lessons[state].id)
        }
    }

    @Test func stateTwo_homeShowsThirdLesson_andTwoCompleted() {
        let module = ModuleProgress(courseID: course.id, state: 2, lastOpenedAt: day)
        let lesson = course.lessons[2]
        let record = LessonProgress(lessonID: lesson.id, courseID: course.id, currentStep: 3, lastOpenedAt: day)
        let summary = CourseRules.summary(of: course, module: module, progress: [lesson.id: record])
        #expect(summary.current == LessonRef(number: 3, title: "Lesson 3", step: 4))
        #expect(summary.completedLessons == 2)
        #expect(summary.completedLessonNumbers == [1, 2])
        #expect(summary.isInProgress)
    }

    @Test func lessonRecords_doNotOverridePersistedModuleState() {
        let later = course.lessons[4]
        let record = LessonProgress(lessonID: later.id, courseID: course.id, currentStep: 4,
            completedAt: day, lastOpenedAt: day, xp: 15)
        let module = ModuleProgress(courseID: course.id, state: 0)
        let records = [later.id: record]
        #expect(CourseRules.entry(for: course, module: module, progress: records)?.lessonID == course.lessons[0].id)
        #expect(CourseRules.summary(of: course, module: module, progress: records).completedLessons == 0)
    }

    @Test func partialFirstLesson_doesNotChangeStateZero() {
        let module = ModuleProgress(courseID: course.id, state: 0, lastOpenedAt: day)
        #expect(CourseRules.state(of: course, module: module) == .inProgress)
        #expect(CourseRules.summary(of: course, module: module, progress: [:]).completedLessons == 0)
    }

    @Test func allCompleted_hasNoNextLesson() {
        let module = ModuleProgress(courseID: course.id, state: 6, lastOpenedAt: day, completedAt: day)
        #expect(CourseRules.entry(for: course, module: module, progress: [:]) == nil)
        #expect(CourseRules.state(of: course, module: module) == .done)
        #expect(!CourseRules.summary(of: course, module: module, progress: [:]).isInProgress)
    }

    @Test func coverCursor_isNotStepZero() {
        let lesson = course.lessons[0]
        let record = LessonProgress(lessonID: lesson.id, courseID: course.id, currentStep: -1, lastOpenedAt: day)
        #expect(CourseRules.entry(for: course, module: nil, progress: [lesson.id: record])?.step == nil)
    }

    @Test func courseKind_readsTheIdPrefix() {
        #expect(CourseKind(courseID: "region-pt-douro") == .region)
        #expect(CourseKind(courseID: "path-01") == .path)
    }
}

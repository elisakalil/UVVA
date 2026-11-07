import Core
import Foundation
import Testing
@testable import You

struct CourseRecommendationPolicyTests {
    private let policy = CourseRecommendationPolicy()
    private let intro = CourseSummary(id: "path-01", title: "What Wine Is", lessonCount: 5, minutes: 15)
    private let path = Course(id: "path-02", kind: .path, order: 2, title: "Types and Styles", about: "", lessons: [])
    private let grape = Course(id: "grape-tempranillo", kind: .grape, order: 1, title: "Tempranillo", about: "", aliases: ["Tinta Roriz"], lessons: [])
    private let region = Course(id: "region-pt-douro", kind: .region, order: 1, title: "Douro", about: "", grapes: ["Tinta Roriz"], lessons: [])

    @Test func introductoryCourseRemainsUntilCompleted() {
        let activity = LearningActivity(lessons: [:], certificates: [Certificate(courseID: grape.id, date: .now)],
                                        startedModuleIDs: [intro.id])
        #expect(policy.select(intro: intro, courses: [path, grape, region], activity: activity)?.reason == .introduction)
    }

    @Test func completedGrapeLeadsToRegionThroughAlias() {
        let activity = LearningActivity(lessons: [:], certificates: [Certificate(courseID: intro.id, date: .now)],
                                        completedModuleDates: [grape.id: .now])
        let suggestion = policy.select(intro: intro, courses: [path, grape, region], activity: activity)
        #expect(suggestion?.course.id == region.id)
        #expect(suggestion?.reason == .linkedRegion(grape: grape.title))
    }

    @Test func skipsStartedAndCompletedCoursesThenRunsOutOfSuggestions() {
        let opened = LessonProgress(lessonID: "lesson", courseID: region.id, currentStep: -1, lastOpenedAt: .now)
        var activity = LearningActivity(lessons: [opened.lessonID: opened], certificates: [
            Certificate(courseID: intro.id, date: .now), Certificate(courseID: grape.id, date: .now)
        ])
        #expect(policy.select(intro: intro, courses: [path, grape, region], activity: activity)?.course.id == path.id)
        activity.startedModuleIDs.insert(path.id)
        #expect(policy.select(intro: intro, courses: [path, grape, region], activity: activity) == nil)
    }
}

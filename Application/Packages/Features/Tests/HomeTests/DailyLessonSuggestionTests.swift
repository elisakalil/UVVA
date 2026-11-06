import Core
import Foundation
import Testing
@testable import Home

struct DailyLessonSuggestionTests {
    private let builder = HomeCardsBuilder(calendar: Calendar(identifier: .gregorian))
    private let day = Date(timeIntervalSince1970: 1_800_014_400)

    private func model() -> HomeContentModel {
        var model = HomeContentModel.full
        model.lessonCatalog = [CourseKind.region, .grape, .path].enumerated().flatMap { index, kind in
            (0..<3).map { variant in
            let id = "course-\(index)-\(variant)"
            return Course(id: id, kind: kind, order: index, title: id, about: "", lessons: (1...12).map {
                LessonSummary(id: "\(id)-\($0)", courseID: id, order: $0, title: "Lesson \($0)",
                              subtitle: "", xp: 15, minutes: 3, isReview: false, objectives: [])
            })
            }
        }
        return model
    }

    @Test func sameDayAndReorderedCatalogKeepExactLessons() {
        var model = model()
        let morning = builder.dailyLessons(model, now: day)
        model.lessonCatalog.reverse()
        let evening = builder.dailyLessons(model, now: day.addingTimeInterval(60))
        #expect(morning == evening)
        #expect(morning.count == 3)
        #expect(Set(morning.map(\.lesson.id)).count == 3)
    }

    @Test func completedLessonsAreExcludedAndExhaustedCategoriesDisappear() {
        var model = model()
        for completed in model.lessonCatalog.filter({ $0.kind == .region }) {
            model.modules[completed.id] = ModuleProgress(courseID: completed.id, state: completed.lessons.count, lastOpenedAt: day)
            for lesson in completed.lessons {
                model.lessonProgress[lesson.id] = LessonProgress(lessonID: lesson.id, courseID: completed.id,
                                                               completedAt: day, lastOpenedAt: day)
            }
        }
        let suggestions = builder.dailyLessons(model, now: day)
        #expect(suggestions.count == 2)
        #expect(suggestions.allSatisfy { $0.course.kind != .region })
        #expect(suggestions.allSatisfy { model.lessonProgress[$0.lesson.id]?.isCompleted != true })
    }

    @Test func dailyPicksVaryAndAlwaysResolveToCatalogLessons() {
        let model = model()
        let picks = (0..<14).map { offset in
            builder.dailyLessons(model, now: day.addingTimeInterval(Double(offset) * 86400))
        }
        #expect(Set(picks.flatMap { $0.map(\.lesson.id) }).count > 3)
        for pick in picks.flatMap({ $0 }) {
            #expect(model.lessonCatalog.contains { $0.id == pick.course.id && $0.lessons.contains(pick.lesson) })
        }
    }

    @Test func moduleReviewsAreNeverSuggested() {
        var model = model()
        for courseIndex in model.lessonCatalog.indices {
            for lessonIndex in model.lessonCatalog[courseIndex].lessons.indices {
                model.lessonCatalog[courseIndex].lessons[lessonIndex].isReview = true
            }
        }
        #expect(builder.dailyLessons(model, now: day).isEmpty)
    }

    @Test func noCatalogProducesNoSuggestions() {
        #expect(builder.dailyLessons(.full, now: day).isEmpty)
    }
    @Test func regionSuggestion_usesPersistedStatePlusOne() {
        var model = model()
        for course in model.lessonCatalog where course.kind == .region {
            model.modules[course.id] = ModuleProgress(courseID: course.id, state: 2, lastOpenedAt: day)
        }
        let region = builder.dailyLessons(model, now: day).first { $0.course.kind == .region }
        #expect(region?.lesson.order == 3)
    }

}

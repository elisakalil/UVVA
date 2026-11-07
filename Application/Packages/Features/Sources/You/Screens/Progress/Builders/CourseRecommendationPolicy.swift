import Core
import Foundation

struct CourseRecommendationPolicy {
    func completionDates(courses: [Course], activity: LearningActivity) -> [String: Date] {
        var dates = activity.completedModuleDates
        for certificate in activity.certificates {
            dates[certificate.courseID] = max(dates[certificate.courseID] ?? certificate.date, certificate.date)
        }
        for course in courses where !course.lessons.isEmpty && dates[course.id] == nil {
            let completed = course.lessons.compactMap { activity.lessons[$0.id]?.completedAt }
            if completed.count == course.lessons.count {
                dates[course.id] = completed.max()
            }
        }
        return dates
    }

    func select(intro: CourseSummary, courses: [Course], activity: LearningActivity) -> CourseRecommendation? {
        let completed = completionDates(courses: courses, activity: activity)
        guard completed[intro.id] != nil else {
            return CourseRecommendation(course: intro, reason: .introduction)
        }

        let started = activity.startedModuleIDs.union(activity.lessons.values.map(\.courseID))
        let candidates = courses.filter { completed[$0.id] == nil && !started.contains($0.id) }
            .sorted { ($0.order, $0.id) < ($1.order, $1.id) }
        let studied = courses.filter { $0.kind != .path && completed[$0.id] != nil }
            .sorted {
                let lhs = completed[$0.id] ?? .distantPast
                let rhs = completed[$1.id] ?? .distantPast
                return lhs == rhs ? $0.id < $1.id : lhs > rhs
            }

        if let anchor = studied.first {
            let related = candidates.filter { connects(anchor, $0) }
            let scored = related.map { candidate in
                (course: candidate, count: studied.filter { connects($0, candidate) }.count)
            }
            if let best = scored.sorted(by: {
                (-$0.count, $0.course.order, $0.course.id) < (-$1.count, $1.course.order, $1.course.id)
            }).first?.course {
                return recommendation(best, reason: anchor.kind == .grape
                    ? .linkedRegion(grape: anchor.title) : .linkedGrape(region: anchor.title))
            }
        }
        if let path = candidates.first(where: { $0.kind == .path }) {
            return recommendation(path, reason: .nextPathModule)
        }
        return candidates.first.map { recommendation($0, reason: .explore) }
    }

    private func connects(_ first: Course, _ second: Course) -> Bool {
        switch (first.kind, second.kind) {
        case (.grape, .region): return GrapeNames.matches(first, in: second)
        case (.region, .grape): return GrapeNames.matches(second, in: first)
        default: return false
        }
    }

    private func recommendation(_ course: Course, reason: CourseRecommendation.Reason) -> CourseRecommendation {
        CourseRecommendation(course: CourseSummary(id: course.id, title: course.title,
                                                  lessonCount: course.lessons.count, minutes: course.minutes),
                             reason: reason)
    }
}

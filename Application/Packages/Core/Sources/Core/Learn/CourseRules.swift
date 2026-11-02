import Foundation

/// The rules every feature shares about a course and the progress of its lessons (LEARN-R02, R11; SHARED-R15 to R17).
/// `progress` is keyed by lesson id.
public enum CourseRules {
    public static func state(of course: Course, progress: [String: LessonProgress]) -> CourseState {
        let opened = course.lessons.compactMap { progress[$0.id] }
        if !course.lessons.isEmpty, opened.count == course.lessons.count, opened.allSatisfy(\.isCompleted) { return .done }
        return opened.isEmpty ? .notStarted : .inProgress
    }

    /// LEARN-R11: lesson 1 when not started or done; otherwise the first lesson not completed, at its saved step.
    public static func entry(for course: Course, progress: [String: LessonProgress]) -> CourseEntry? {
        guard let first = course.lessons.first else { return nil }
        guard state(of: course, progress: progress) == .inProgress,
              let next = course.lessons.first(where: { !(progress[$0.id]?.isCompleted ?? false) }) else {
            return CourseEntry(lessonID: first.id, step: nil)
        }
        return CourseEntry(lessonID: next.id, step: progress[next.id]?.currentStep)
    }

    /// The course as Home and You show it (HOME-R12, R13).
    public static func summary(of course: Course, progress: [String: LessonProgress]) -> CourseProgress {
        let opened = course.lessons.compactMap { progress[$0.id] }
        let entry = state(of: course, progress: progress) == .inProgress ? entry(for: course, progress: progress) : nil
        let current = entry.flatMap { entry in
            course.lessons.first { $0.id == entry.lessonID }.map {
                LessonRef(number: $0.order, title: $0.title, step: (entry.step ?? 0) + 1)
            }
        }
        return CourseProgress(id: course.id, title: course.title, totalLessons: course.lessons.count,
                              completedLessons: opened.filter(\.isCompleted).count, hasStarted: !opened.isEmpty,
                              lastOpenedAt: opened.map(\.lastOpenedAt).max(), current: current)
    }
}

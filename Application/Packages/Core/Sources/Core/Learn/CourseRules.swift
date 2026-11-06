import Foundation

/// Presentation of persisted module state. Never reconstructs a cursor from lesson records.
public enum CourseRules {
    public static func state(of course: Course, module: ModuleProgress?) -> CourseState {
        guard let module else { return .notStarted }
        if !course.lessons.isEmpty, module.state >= course.lessons.count { return .done }
        return module.state > 0 || module.lastOpenedAt != nil ? .inProgress : .notStarted
    }

    public static func entry(for course: Course, module: ModuleProgress?, progress: [String: LessonProgress]) -> CourseEntry? {
        let state = module?.state ?? 0
        guard state >= 0, course.lessons.indices.contains(state) else { return nil }
        let lesson = course.lessons[state] // state 0 -> lesson 1; state 1 -> lesson 2.
        let step = progress[lesson.id].flatMap { $0.currentStep >= 0 ? $0.currentStep : nil }
        return CourseEntry(lessonID: lesson.id, step: step)
    }

    public static func summary(of course: Course, module: ModuleProgress?, progress: [String: LessonProgress]) -> CourseProgress {
        let completed = min(max(module?.state ?? 0, 0), course.lessons.count)
        let entry = entry(for: course, module: module, progress: progress)
        let current = entry.flatMap { entry in
            course.lessons.first { $0.id == entry.lessonID }.map {
                LessonRef(number: $0.order, title: $0.title, step: (entry.step ?? 0) + 1)
            }
        }
        return CourseProgress(id: course.id, title: course.title, totalLessons: course.lessons.count,
            completedLessons: completed, hasStarted: module?.lastOpenedAt != nil || completed > 0,
            lastOpenedAt: module?.lastOpenedAt, current: current)
    }
}

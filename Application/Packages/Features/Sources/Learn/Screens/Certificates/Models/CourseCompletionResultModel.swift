import Core

struct CourseCompletionResultModel {
    let progress: [String: LessonProgress]
    let certificates: [Certificate]
    let earned: Certificate?
    var modules: [String: ModuleProgress] = [:]
}

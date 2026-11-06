import Core

struct LearnContentModel {
    var courses: [CourseKind: [Course]] = [:]
    var progress: [String: LessonProgress] = [:]
    var modules: [String: ModuleProgress] = [:]
    var certificates: [Certificate] = []
    var firstName = ""
}

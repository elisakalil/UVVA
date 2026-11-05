import Core

struct LearnContent {
    var courses: [CourseKind: [Course]] = [:]
    var progress: [String: LessonProgress] = [:]
    var certificates: [Certificate] = []
    var firstName = ""
}

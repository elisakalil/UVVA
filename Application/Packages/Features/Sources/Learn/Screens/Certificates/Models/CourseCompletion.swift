import Core

struct CourseCompletion {
    let progress: [String: LessonProgress]
    let certificates: [Certificate]
    let earned: Certificate?
}

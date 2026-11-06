import Core

/// Data shared by the You screens; it contains no presentation or navigation logic.
struct YouContentModel {
    var profile: Profile?
    var map: PalateMap?
    var history: [MapChange] = []
    var reminder: Reminder?
    var firstModule: CourseSummary?
    var lessons: [String: LessonProgress] = [:]
    var certificates: [Certificate] = []
    var certificateCourses: [String: Course] = [:]
}

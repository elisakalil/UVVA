import Core

/// Data shared by the You screens; it contains no presentation or navigation logic.
struct YouContentModel {
    var profile: Profile?
    var map: PalateMap?
    var history: [MapChange] = []
    var reminder: Reminder?
    var recommendation: CourseRecommendation?
    var recommendationStatus: RecommendationStatus = .loading

    enum RecommendationStatus { case loading, ready, unavailable }
    var lessons: [String: LessonProgress] = [:]
    var certificates: [Certificate] = []
    var regionCatalog: [Course] = []
    var certificateCourses: [String: Course] = [:]
}

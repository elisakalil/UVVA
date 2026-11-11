import Core
import Foundation

struct HomeContentModel: Sendable {
    var firstName: String
    var palateMap: PalateMap
    var friends: [Friend]
    var courses: [CourseProgress]
    var lastRating: Rating?
    /// HOME-R24: the verdict of each wine rated since the Quiz.
    var ratedVerdicts: [String: Verdict]
    /// HOME-R23: the wines in the Cellar, tasted or not.
    var cellarWineKeys: Set<String> = []
    var catalog: [Wine]
    var glossary: [GlossaryTerm]
    var notifications: [AppNotification]
    var lessonCatalog: [Course] = []
    var modules: [String: ModuleProgress] = [:]
    var lessonProgress: [String: LessonProgress] = [:]
}

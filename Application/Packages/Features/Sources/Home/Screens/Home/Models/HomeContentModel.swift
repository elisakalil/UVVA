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
    /// The new wines of the catalog (none in the Cellar, HOME-R08a), closest to the map first, the Hero's with its
    /// dish: what the Hero, "A wine for each strong trait" and "Choose yourself" suggest from.
    var catalog: [Wine]
    var glossary: [GlossaryTerm]
    var notifications: [AppNotification]
    var lessonCatalog: [Course] = []
    var modules: [String: ModuleProgress] = [:]
    var lessonProgress: [String: LessonProgress] = [:]
}

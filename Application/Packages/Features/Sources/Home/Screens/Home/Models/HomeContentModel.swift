import Core
import Foundation

struct HomeContentModel: Sendable {
    var firstName: String
    var palateMap: PalateMap
    var friends: [Friend]
    var courses: [CourseProgress]
    var lastRating: Rating?
    var ratedWineIDs: Set<String>
    var catalog: [Wine]
    var glossary: [GlossaryTerm]
    var notifications: [AppNotification]
    var lessonCatalog: [Course] = []
    var modules: [String: ModuleProgress] = [:]
    var lessonProgress: [String: LessonProgress] = [:]
}

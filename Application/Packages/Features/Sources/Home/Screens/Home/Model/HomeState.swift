import Core
import Foundation

struct HomeState: Sendable {
    var firstName: String
    var palateMap: PalateMap
    var friends: [Friend]
    var courses: [CourseProgress]
    var lastRating: Rating?
    var ratedWineIDs: Set<String>
    var catalog: [Wine]
    var glossary: [GlossaryTerm]
    var notifications: [AppNotification]
}

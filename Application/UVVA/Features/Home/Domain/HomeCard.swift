import Foundation

/// Everything the Home reads (home.md, section 2).
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

/// One card per case, in the fixed order of HOME-R01.
enum HomeCard: Equatable, Sendable {
    case header(greeting: String, hasUnread: Bool)
    case dailySuggestion(Wine)
    case friends(FriendsVariant)
    case continueLesson(CourseProgress)
    case changedMapCard(axis: Axis, delta: Double)
    case learnShortcuts
    case wordOfTheDay(GlossaryTerm)
    case winesForPalate([Wine])
    case chooseYourWine

    enum FriendsVariant: Equatable, Sendable {
        case invite
        case match(Friend)
        case setTable(count: Int)
    }

    /// Stable identity for SwiftUI lists.
    var kind: String {
        switch self {
        case .header: "header"
        case .dailySuggestion: "dailySuggestion"
        case .friends: "friends"
        case .continueLesson: "continueLesson"
        case .changedMapCard: "changedMapCard"
        case .learnShortcuts: "learnShortcuts"
        case .wordOfTheDay: "wordOfTheDay"
        case .winesForPalate: "winesForPalate"
        case .chooseYourWine: "chooseYourWine"
        }
    }
}

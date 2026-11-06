import Core
import Foundation

/// One card per case, in the fixed order of HOME-R01.
enum HomeCardModel: Equatable, Sendable {
    case header(greeting: String, hasUnread: Bool)
    case dailySuggestion(Wine)
    case friends(FriendsCardState)
    case continueLesson(CourseProgress)
    case changedMapCard(axis: PalateAxis, delta: Double)
    case learnShortcuts([HomeLessonSuggestion])
    case wordOfTheDay(GlossaryTerm)
    case winesForPalate([Wine])
    case chooseYourWine

    enum FriendsCardState: Equatable, Sendable {
        case noFriends
        case hasMatch(Friend)
        case hasFriends(count: Int)
    }

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
    
    var isHalfWidth: Bool {
        switch self {
        case .continueLesson, .changedMapCard: true
        default: false
        }
    }

    var spotlightID: String? {
        switch self {
        case .dailySuggestion: HomeSpotlightID.today
        case .friends: HomeSpotlightID.friends
        case .chooseYourWine: HomeSpotlightID.chooseYourWine
        default: nil
        }
    }
}

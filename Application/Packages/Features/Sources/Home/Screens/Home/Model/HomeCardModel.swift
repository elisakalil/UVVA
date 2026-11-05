import Core
import Foundation

/// One card per case, in the fixed order of HOME-R01.
enum HomeCardModel: Equatable, Sendable {
    case header(greeting: String, hasUnread: Bool)
    case dailySuggestion(Wine)
    case friends(FriendsVariant)
    case continueLesson(CourseProgress)
    case changedMapCard(axis: PalateAxis, delta: Double)
    case learnShortcuts
    case wordOfTheDay(GlossaryTerm)
    case winesForPalate([Wine])
    case chooseYourWine

    enum FriendsVariant: Equatable, Sendable {
        case invite
        case match(Friend)
        case setTable(count: Int)
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
        case .dailySuggestion: HomeSpotlightModel.today
        case .friends: HomeSpotlightModel.friends
        case .chooseYourWine: HomeSpotlightModel.chooseYourWine
        default: nil
        }
    }
}

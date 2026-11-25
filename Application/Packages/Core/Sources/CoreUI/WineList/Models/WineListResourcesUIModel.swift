import Core
import Foundation

struct WineListResourcesUIModel {
    // MARK: The switch on the scan (WINELIST-R01)
    var labelModeText = String(localized: "Label", bundle: .module)
    var listModeText = String(localized: "Wine list", bundle: .module)

    // MARK: Camera (WINELIST-R03)
    var captureTitleText = String(localized: "The wine list", bundle: .module)
    var captureHintText = String(localized: "Fit one page in the frame, flat and in the light.", bundle: .module)
    var readingTitleText = String(localized: "Reading the list", bundle: .module)
    /// The page the camera is on: the next one to read.
    func pageText(_ number: Int) -> String { String(localized: "Page \(number)", bundle: .module) }
    func winesFoundText(_ count: Int) -> String {
        count == 1 ? String(localized: "1 wine found", bundle: .module)
            : String(localized: "\(count) wines found", bundle: .module)
    }
    func fitText(_ count: Int) -> String {
        switch count {
        case 0: String(localized: "Turn the page if there’s more.", bundle: .module)
        case 1: String(localized: "One already fits your palate. Turn the page if there’s more.", bundle: .module)
        default: String(localized: "\(count) already fit your palate. Turn the page if there’s more.", bundle: .module)
        }
    }
    var noWinesText = String(localized: "No wines on this page. Try it closer, flat and in the light.", bundle: .module)
    var readFailedText = String(localized: "We couldn’t read this page. Try again.", bundle: .module)
    var useListText = String(localized: "Use this list", bundle: .module)
    var shutterText = String(localized: "Take photo", bundle: .module)
    var libraryText = String(localized: "Choose from library", bundle: .module)
    var libraryIcon = "photo.on.rectangle"
    var cameraUnavailableText = String(localized: "No camera on this device", bundle: .module)
    var deniedTitleText = String(localized: "The camera is off", bundle: .module)
    var deniedBodyText = String(localized: "UVVA needs the camera to read the wine list. Turn it on in Settings.", bundle: .module)

    // MARK: What's on the table? (WINELIST-R06)
    func winesOnListText(_ count: Int) -> String {
        count == 1 ? String(localized: "1 wine on the list", bundle: .module)
            : String(localized: "\(count) wines on the list", bundle: .module)
    }
    var questionsTitleText = String(localized: "What’s on the table?", bundle: .module)
    var questionsBodyText = String(localized: "Pick what you ordered. Skip anything you don’t know yet.", bundle: .module)
    var dishLabelText = String(localized: "The dish", bundle: .module)
    var budgetLabelText = String(localized: "A bottle, up to", bundle: .module)
    var noLimitText = String(localized: "No limit", bundle: .module)
    var peopleLabelText = String(localized: "Who’s drinking", bundle: .module)
    var youText = String(localized: "You", bundle: .module)
    var peopleNoteText = String(localized: "Friends with a palate map are read together.", bundle: .module)
    var orderButtonText = String(localized: "Tell me what to order", bundle: .module)
    var backText = String(localized: "Back", bundle: .module)

    func dishText(_ dish: MenuDish) -> String {
        switch dish {
        case .fish: String(localized: "Fish", bundle: .module)
        case .shellfish: String(localized: "Seafood", bundle: .module)
        case .poultry: String(localized: "Chicken", bundle: .module)
        case .pork: String(localized: "Pork", bundle: .module)
        case .redMeat: String(localized: "Red meat", bundle: .module)
        case .game: String(localized: "Game", bundle: .module)
        case .vegetables: String(localized: "Vegetables", bundle: .module)
        case .cheese: String(localized: "Cheese", bundle: .module)
        case .dessert: String(localized: "Dessert", bundle: .module)
        }
    }

    // MARK: Order this (WINELIST-R07)
    var orderThisText = String(localized: "Order this", bundle: .module)
    var howToAskText = String(localized: "How to ask for it", bundle: .module)
    var closeSecondText = String(localized: "Close second", bundle: .module)
    var cheaperText = String(localized: "Same feel, less money", bundle: .module)
    var differentText = String(localized: "Something different", bundle: .module)
    var alsoText = String(localized: "Also on the list", bundle: .module)
    var overBudgetText = String(localized: "Over budget", bundle: .module)
    var estimatedText = String(localized: "Read from the list", bundle: .module)
    var nothingInBudgetText = String(localized: "No wine on this list fits the budget. These are the closest.", bundle: .module)
    var emptyTitleText = String(localized: "No wine to suggest", bundle: .module)
    var emptyBodyText = String(localized: "We couldn’t tell any wine on this list apart. Try another photo of it.", bundle: .module)
    var forYouText = String(localized: "For you", bundle: .module)
    func forPeopleText(_ count: Int) -> String { String(localized: "For \(count)", bundle: .module) }
    func upToText(_ price: String) -> String { String(localized: "up to \(price)", bundle: .module) }
    var anyPriceText = String(localized: "any price", bundle: .module)
    func placeText(position: Int, section: String) -> String {
        String(localized: "No. \(position) in \(section)", bundle: .module)
    }
    func footText(maps: Int, wines: Int) -> String {
        maps == 1 ? String(localized: "Read from your palate map · \(wines) wines", bundle: .module)
            : String(localized: "Read from \(maps) palate maps · \(wines) wines", bundle: .module)
    }

    // The reason, palate then dish.
    func sharedText(_ first: String, _ second: String?) -> String {
        guard let second else { return String(localized: "High in \(first), like your palate.", bundle: .module) }
        return String(localized: "High in \(first) and \(second), like your palate.", bundle: .module)
    }
    func moreThanUsualText(_ axis: String) -> String {
        String(localized: "More \(axis) than you usually like.", bundle: .module)
    }
    func lessThanUsualText(_ axis: String) -> String {
        String(localized: "Less \(axis) than you usually like.", bundle: .module)
    }
    var closeEverywhereText = String(localized: "Close to your palate on every axis.", bundle: .module)
    func tableText(_ count: Int) -> String {
        String(localized: "The closest to all \(count) palate maps.", bundle: .module)
    }
    func madeForText(_ dishes: String) -> String { String(localized: "Made for \(dishes).", bundle: .module) }
    func holdsUpText(_ dishes: String) -> String { String(localized: "Holds up to \(dishes).", bundle: .module) }
    func notObviousText(_ dishes: String) -> String {
        String(localized: "Not the obvious match for \(dishes).", bundle: .module)
    }

    // MARK: Say it or show it (WINELIST-R08)
    var addToCellarText = String(localized: "It’s on the table · add to Cellar", bundle: .module)
    var closeText = String(localized: "Close", bundle: .module)
}

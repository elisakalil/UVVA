import Foundation

struct QuizResourcesUIModel {
    var changeQuestionText = String(localized: "Change question", bundle: .module)
    var positionText = String(localized: "Position", bundle: .module)
    var thisMapKeepsMovingText = String(localized: "This map keeps moving", bundle: .module)
    var everyTimeYouSaveAText = String(localized: "Every time you save a note on a wine you liked, UVVA recalculates your eight readings. The map you see here is your taste today, not a verdict.", bundle: .module)
    var palateMapText = String(localized: "Palate map", bundle: .module)
    var yourTasteIsText = String(localized: "Your taste is", bundle: .module)
    var yourReadingsText = String(localized: "Your readings", bundle: .module)
    var whereTheMapPointsText = String(localized: "Where the map points", bundle: .module)
    var keepThisMapText = String(localized: "Keep this map", bundle: .module)
    var readItAgainText = String(localized: "Read it again", bundle: .module)
    var theMapCouldNotBeText = String(localized: "The map could not be saved. Try again.", bundle: .module)
    var shareYourMapText = String(localized: "Share your map", bundle: .module)
    var lovesText = String(localized: "Loves", bundle: .module)
    var neverText = String(localized: "Never", bundle: .module)
    func readingAccessibility(current: Int, count: Int) -> String {
        String(localized: "Reading \(current + 1) of \(count)", bundle: .module)
    }
}

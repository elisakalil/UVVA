import Foundation

struct QuizResourcesUIModel {
    var changeQuestionText = String(localized: "Change question", bundle: .module)
    var positionText = String(localized: "Position", bundle: .module)
    var thisMapKeepsMovingText = String(localized: "This map keeps moving", bundle: .module)
    var everyTimeYouSaveAText = String(localized: "Every time you save a note on a wine you liked, UVVA recalculates your eight readings. The map you see here is your taste today, not a verdict.", bundle: .module)
    var palateMapText = String(localized: "Palate map", bundle: .module)
    var yourTasteIsText = String(localized: "Your taste is", bundle: .module)
    var yourReadingsText = String(localized: "Your readings", bundle: .module)
    /// QUIZ-R04a to R04c, in the sheet of "Where the map points": the map is the answers settled among real wines,
    /// not the answers.
    var howTheMapIsDrawnText = String(localized: "How your map is drawn", bundle: .module)
    var answersStartingPointText = String(localized: "Your answers were the starting point. We read them in wine terms and settled them among real wines, so your map points to bottles that exist. What you lean toward stays: love floral, and your map leans to the more floral wines.", bundle: .module)
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

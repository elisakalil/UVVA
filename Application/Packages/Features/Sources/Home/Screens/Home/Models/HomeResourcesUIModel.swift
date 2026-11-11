import Foundation
import Core
import DesignSystem
import SwiftUI

/// Localized content and asset identifiers shared by Home and its visual components.
struct HomeResourcesUIModel {
    var homeFooterVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    var homeFooterOrigin = String(localized: "Made in Portugal", bundle: .module)
    var homeHeaderBrand = String(localized: "UVVA", bundle: .module)
    var homeHeaderScanSymbol = "+"
    var homeHeaderScanLabel = String(localized: "Scan a label", bundle: .module)
    var homeHeaderUnreadLabel = String(localized: "Notifications, unread", bundle: .module)
    var homeHeaderNotificationsLabel = String(localized: "Notifications", bundle: .module)
    var dailySuggestionCardFindWineTitle = String(localized: "Find the wine", bundle: .module)
    var dailySuggestionCardSavedTitle = String(localized: "In your cellar", bundle: .module)
    var dailySuggestionCardAddTitle = String(localized: "Add to cellar", bundle: .module)
    var dailySuggestionCardExpandTitle = String(localized: "See the wine & the dish", bundle: .module)
    var dailySuggestionCardCollapseTitle = String(localized: "Show less", bundle: .module)
    var dailySuggestionCardSavedIcon = "checkmark"
    var dailySuggestionCardExpandIcon = "chevron.down"
    var dailySuggestionCardCollapseIcon = "chevron.up"
    var friendsCardInviteTitle = String(localized: "Invite friends to discover their palate and find a wine you'll both love", bundle: .module)
    var friendsCardOpenTableTitle = String(localized: "Open the table →", bundle: .module)
    var friendsCardTableTitle = String(localized: "Set a table with your friends", bundle: .module)
    var friendsCardPickFriendsTitle = String(localized: "Pick who is coming →", bundle: .module)
    var continueLessonCardContinueTitle = String(localized: "Continue  →", bundle: .module)
    var learnShortcutsCardRegionEyebrow = String(localized: "Learn a region", bundle: .module)
    var learnShortcutsCardRegionTitle = String(localized: "Uco Valley", bundle: .module)
    var learnShortcutsCardRegionSubtitle = String(localized: "Malbec at altitude", bundle: .module)
    var learnShortcutsCardLessonCount = String(localized: "6 lessons", bundle: .module)
    var learnShortcutsCardGrapeEyebrow = String(localized: "Learn a grape", bundle: .module)
    var learnShortcutsCardGrapeTitle = String(localized: "Tempranillo", bundle: .module)
    var learnShortcutsCardGrapeSubtitle = String(localized: "Spain's great red", bundle: .module)
    var learnShortcutsCardLessonEyebrow = String(localized: "Learn a lesson", bundle: .module)
    var learnShortcutsCardLessonTitle = String(localized: "Organic, biodynamic and natural", bundle: .module)
    var learnShortcutsCardLessonSubtitle = String(localized: "What the labels really mean", bundle: .module)
    var learnShortcutsCardStartTitle = String(localized: "Start", bundle: .module)
    var winesForPalateCardTitle = String(localized: "A wine for each strong trait of your map", bundle: .module)
    var wordOfTheDayCardSectionTitle = String(localized: "Word of the day", bundle: .module)
    var chooseYourWineCardTitle = String(localized: "Choose yourself", bundle: .module)
    var chooseYourWineFamiliarTitle = String(localized: "For my palate", bundle: .module)
    var chooseYourWineSurpriseTitle = String(localized: "Surprise me", bundle: .module)
    var chooseYourWineNoMatch = String(localized: "No wines match these choices. Try changing a filter.", bundle: .module)
    var chooseYourWineAnotherTitle = String(localized: "Another one", bundle: .module)
    var chooseYourWineCardTypeTitle = String(localized: "Type", bundle: .module)
    var chooseYourWinePairingTitle = String(localized: "Food pairing", bundle: .module)
    var chooseYourWineCardRegionTitle = String(localized: "Region", bundle: .module)
    var chooseYourWineCardNotesTitle = String(localized: "Notes", bundle: .module)
    var chooseYourWineCardNotesHint = String(localized: "Pick up to three", bundle: .module)
    var chooseYourWineCardFindTitle = String(localized: "Find my wine", bundle: .module)
    var perfectTableTitle = String(localized: "The perfect table", bundle: .module)
    var perfectTableIngredientsTitle = String(localized: "What you need", bundle: .module)
    var perfectTableStepsTitle = String(localized: "How to make it", bundle: .module)
    var wineMapPagerWineMapTitle = String(localized: "The map of this wine", bundle: .module)
    var wineMapPagerComparisonTitle = String(localized: "This wine and you", bundle: .module)
    var wineMapPagerWineLegend = String(localized: "This wine", bundle: .module)
    var wineMapPagerPalateLegend = String(localized: "Your map", bundle: .module)
    var wineRowChevronIcon = "chevron.right"
    var wineFactsOriginTitle = String(localized: "Origin", bundle: .module)
    var wineFactsAppellationTitle = String(localized: "Appellation", bundle: .module)
    var wineFactsGrapesTitle = String(localized: "Grapes", bundle: .module)
    var wineFactsNotesTitle = String(localized: "Notes", bundle: .module)
    var wineFactsServingTitle = String(localized: "Serve at", bundle: .module)
    var wineFactsVintageTitle = String(localized: "Vintage", bundle: .module)

    var wineMapPagerOverlapLegend = String(localized: "In common", bundle: .module)
    var wineDetailPickTitle = String(localized: "Your pick", bundle: .module)
    var wineDetailShowAnother = String(localized: "Show another ›", bundle: .module)
    var wineDetailAwayCaption = String(localized: "away from your map", bundle: .module)
    var wineDetailStyleTitle = String(localized: "Style", bundle: .module)
    var wineDetailGrapeNotesTitle = String(localized: "Grape & notes", bundle: .module)
    var wineDetailPairingsTitle = String(localized: "Pairings", bundle: .module)
    var wineDetailNonVintage = String(localized: "Non-vintage", bundle: .module)
    var wineDetailServeTitle = String(localized: "How to serve", bundle: .module)
    var wineDetailTastedQuestion = String(localized: "Have you had this wine?", bundle: .module)
    var wineDetailNotYetTitle = String(localized: "Not yet", bundle: .module)
    var wineDetailVerdictQuestion = String(localized: "Would you drink it again?", bundle: .module)

    var palateMatchTitle = String(localized: "With your palate", bundle: .module)
    var palateMatchCaption = String(localized: "match with your map", bundle: .module)
    var plateImage: Image { UVVAIllustration.plate }
    var maximumNotes = 3

    func wineFilterLabel(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .module)
    }

    func mapChange(axis: PalateAxis, delta: Double) -> String {
        delta >= 0
            ? String(localized: "Your last wine raised your \(axis.rawValue) notes.", bundle: .module)
            : String(localized: "Your last wine lowered your \(axis.rawValue) notes.", bundle: .module)
    }

    func wineRowAxisLabel(_ axis: PalateAxis, level: PalateWineSuggestion.Level) -> String {
        switch (axis, level) {
        case (.floral, .high): String(localized: "High floral", bundle: .module)
        case (.floral, .low): String(localized: "Low floral", bundle: .module)
        case (.body, .high): String(localized: "Full body", bundle: .module)
        case (.body, .low): String(localized: "Light body", bundle: .module)
        case (.tannin, .high): String(localized: "High tannin", bundle: .module)
        case (.tannin, .low): String(localized: "Low tannin", bundle: .module)
        case (.spice, .high): String(localized: "High spice", bundle: .module)
        case (.spice, .low): String(localized: "Low spice", bundle: .module)
        case (.oak, .high): String(localized: "High oak", bundle: .module)
        case (.oak, .low): String(localized: "Low oak", bundle: .module)
        case (.sweetness, .high): String(localized: "High sweetness", bundle: .module)
        case (.sweetness, .low): String(localized: "Low sweetness", bundle: .module)
        case (.acidity, .high): String(localized: "High acidity", bundle: .module)
        case (.acidity, .low): String(localized: "Low acidity", bundle: .module)
        case (.fruit, .high): String(localized: "High fruit", bundle: .module)
        case (.fruit, .low): String(localized: "Low fruit", bundle: .module)
        }
    }

    func wineRowReason(_ suggestion: PalateWineSuggestion) -> String {
        let phrases = wineRowReasons(suggestion.axis, level: suggestion.level)
        // A stable index keeps the copy from changing when SwiftUI redraws the row.
        let index = suggestion.wine.id.utf8.reduce(0) { index, byte in
            (index * 33 + Int(byte)) % phrases.count
        }
        return phrases[index]
    }

    private func wineRowReasons(_ axis: PalateAxis, level: PalateWineSuggestion.Level) -> [String] {
        switch (axis, level) {
        case (.floral, .high):
            [
                String(localized: "Love floral notes? This one's full of them.", bundle: .module),
                String(localized: "The floral notes come through loud and clear.", bundle: .module),
                String(localized: "Take a sniff. The floral aromas stand out.", bundle: .module),
                String(localized: "If you're after a floral wine, try this one.", bundle: .module),
                String(localized: "Lots of floral character in this glass.", bundle: .module)
            ]
        case (.floral, .low):
            [
                String(localized: "Just a hint of flowers here.", bundle: .module),
                String(localized: "The floral aromas are barely there.", bundle: .module),
                String(localized: "Go for this one if you want less perfume.", bundle: .module),
                String(localized: "There's a little floral character in the background.", bundle: .module),
                String(localized: "The floral side of this wine is pretty subtle.", bundle: .module)
            ]
        case (.body, .high):
            [
                String(localized: "This one's got the weight you enjoy.", bundle: .module),
                String(localized: "This one's on the fuller side.", bundle: .module),
                String(localized: "Want something with a bit of heft? Try this.", bundle: .module),
                String(localized: "It feels full and substantial on the palate.", bundle: .module),
                String(localized: "This has that weighty feel you like in a wine.", bundle: .module)
            ]
        case (.body, .low):
            [
                String(localized: "Light on the palate, the way you like it.", bundle: .module),
                String(localized: "This one's got a lighter feel.", bundle: .module),
                String(localized: "Go for this if you want something light-bodied.", bundle: .module),
                String(localized: "It feels light from the first sip.", bundle: .module),
                String(localized: "In the mood for a lighter wine? Here's one.", bundle: .module)
            ]
        case (.tannin, .high):
            [
                String(localized: "There's plenty of that tannic grip you like.", bundle: .module),
                String(localized: "Expect a firm, drying feel on the finish.", bundle: .module),
                String(localized: "The tannins give this wine a real grip.", bundle: .module),
                String(localized: "Like a wine that makes your mouth pucker a bit? Try this.", bundle: .module),
                String(localized: "You'll feel the tannins with the first sip.", bundle: .module)
            ]
        case (.tannin, .low):
            [
                String(localized: "Soft tannins, so it won't dry out your mouth as much.", bundle: .module),
                String(localized: "There's very little tannic grip here.", bundle: .module),
                String(localized: "This one's a good pick if you want less tannin.", bundle: .module),
                String(localized: "The tannins are light on the palate.", bundle: .module),
                String(localized: "Expect less of that mouth-drying feeling.", bundle: .module)
            ]
        case (.spice, .high):
            [
                String(localized: "If you're in the mood for spice, try this one.", bundle: .module),
                String(localized: "The spice notes are easy to pick out.", bundle: .module),
                String(localized: "There's a real kick of spice in this one.", bundle: .module),
                String(localized: "Try this if you want the spice to stand out.", bundle: .module),
                String(localized: "Spice is one of the first things you'll notice.", bundle: .module)
            ]
        case (.spice, .low):
            [
                String(localized: "The spice stays in the background.", bundle: .module),
                String(localized: "Just a light touch of spice here.", bundle: .module),
                String(localized: "Try this for something less spiced.", bundle: .module),
                String(localized: "The spice notes are easy to miss.", bundle: .module),
                String(localized: "The spice is there in small doses.", bundle: .module)
            ]
        case (.oak, .high):
            [
                String(localized: "You'll pick up plenty of oak here.", bundle: .module),
                String(localized: "If you enjoy a noticeable oak note, try this.", bundle: .module),
                String(localized: "The oak stands out as you sip.", bundle: .module),
                String(localized: "Expect a strong oak character in this glass.", bundle: .module),
                String(localized: "There's a good dose of oak here.", bundle: .module)
            ]
        case (.oak, .low):
            [
                String(localized: "The oak is subtle in this one.", bundle: .module),
                String(localized: "There's only a touch of oak here.", bundle: .module),
                String(localized: "Try this if you prefer a lighter oak note.", bundle: .module),
                String(localized: "Oak stays in the background as you sip.", bundle: .module),
                String(localized: "You might just catch a hint of oak.", bundle: .module)
            ]
        case (.sweetness, .high):
            [
                String(localized: "Want something sweeter? Give this a try.", bundle: .module),
                String(localized: "The sweetness is easy to notice here.", bundle: .module),
                String(localized: "This one's got a sweeter feel from the first sip.", bundle: .module),
                String(localized: "If a sweet sip sounds good, pour this one.", bundle: .module),
                String(localized: "There's a good bit of sweetness in the glass.", bundle: .module)
            ]
        case (.sweetness, .low):
            [
                String(localized: "If you like your wine on the drier side, try this.", bundle: .module),
                String(localized: "There's little sweetness in this sip.", bundle: .module),
                String(localized: "This leans toward the dry side.", bundle: .module),
                String(localized: "Want a wine with less sweetness? Go for this.", bundle: .module),
                String(localized: "The sweetness stays low here.", bundle: .module)
            ]
        case (.acidity, .high):
            [
                String(localized: "That mouthwatering acidity you like? It's here.", bundle: .module),
                String(localized: "Expect a bright, tangy sip.", bundle: .module),
                String(localized: "This one has plenty of freshness from its acidity.", bundle: .module),
                String(localized: "Try this if you want a wine with a lively edge.", bundle: .module),
                String(localized: "The acidity gives this wine a real zip.", bundle: .module)
            ]
        case (.acidity, .low):
            [
                String(localized: "Gentle acidity, with less of that sharp bite.", bundle: .module),
                String(localized: "The acidity is easygoing here.", bundle: .module),
                String(localized: "If you want less tang, try this one.", bundle: .module),
                String(localized: "This has a softer feel thanks to its low acidity.", bundle: .module),
                String(localized: "There's just a little lift from the acidity.", bundle: .module)
            ]
        case (.fruit, .high):
            [
                String(localized: "This one's all about the fruit.", bundle: .module),
                String(localized: "You'll get lots of fruit in the glass.", bundle: .module),
                String(localized: "In the mood for something fruity? Go for this.", bundle: .module),
                String(localized: "The fruit comes through clearly as you sip.", bundle: .module),
                String(localized: "Fruit is front and center in this one.", bundle: .module)
            ]
        case (.fruit, .low):
            [
                String(localized: "The fruit notes are pretty quiet here.", bundle: .module),
                String(localized: "Just a little fruit peeks through.", bundle: .module),
                String(localized: "Try this if you prefer a less fruity wine.", bundle: .module),
                String(localized: "The fruit plays a small part in this glass.", bundle: .module),
                String(localized: "There's a faint fruit note in the background.", bundle: .module)
            ]
        }
    }

    func verdictLabel(_ verdict: Verdict) -> String {
        switch verdict {
        case .yes: String(localized: "Yes", bundle: .module)
        case .maybe: String(localized: "Maybe", bundle: .module)
        case .no: String(localized: "No", bundle: .module)
        }
    }

    /// "Saved to Cellar · Pontoforte" (HOME-R28).
    func savedToCellarNotice(_ wine: Wine) -> String {
        String(localized: "Saved to Cellar · \(wine.name)", bundle: .module)
    }

    /// "Map updated · Acidity ↑ · Fruit ↑": the axes that moved, in the canonical order (HOME-R24, QUIZ-R23);
    /// "Saved to Cellar · Map updated · …" when the wine went to the Cellar too.
    func mapUpdatedNotice(_ moves: [(axis: PalateAxis, up: Bool)], savedToCellar: Bool = false) -> String {
        var parts: [String] = []
        if savedToCellar { parts.append(String(localized: "Saved to Cellar", bundle: .module)) }
        parts.append(String(localized: "Map updated", bundle: .module))
        if moves.isEmpty {
            parts.append(String(localized: "barely moved", bundle: .module))
        } else {
            parts += moves.map { "\($0.axis.label) \($0.up ? "↑" : "↓")" }
        }
        return parts.joined(separator: " · ")
    }

    func compatibility(_ value: Int) -> String { "\(value)%" }
    func friendMatch(_ name: String) -> String { String(localized: "match with \(name)", bundle: .module) }
    func lessonTotal(_ count: Int) -> String { "/\(count)" }
}

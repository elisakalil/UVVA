import Foundation
import Core
import DesignSystem
import SwiftUI

/// Localized content and asset identifiers shared by Home and its visual components.
struct HomeResourcesUIModel {
    var homeContentFooter = String(localized: "UVVA · 0.1 · Made in Portugal", bundle: .module)
    var homeHeaderBrand = String(localized: "UVVA", bundle: .module)
    var homeHeaderScanSymbol = "+"
    var homeHeaderScanLabel = String(localized: "Scan a label", bundle: .module)
    var homeHeaderUnreadLabel = String(localized: "Notifications, unread", bundle: .module)
    var homeHeaderNotificationsLabel = String(localized: "Notifications", bundle: .module)
    var dailySuggestionCardPickedTitle = String(localized: "Picked for your palate", bundle: .module)
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
    var learnShortcutsCardSectionTitle = String(localized: "Learn", bundle: .module)
    var learnShortcutsCardRegionEyebrow = String(localized: "A region", bundle: .module)
    var learnShortcutsCardRegionTitle = String(localized: "Uco Valley", bundle: .module)
    var learnShortcutsCardRegionSubtitle = String(localized: "Malbec at altitude", bundle: .module)
    var learnShortcutsCardLessonCount = String(localized: "6 lessons", bundle: .module)
    var learnShortcutsCardGrapeEyebrow = String(localized: "A grape", bundle: .module)
    var learnShortcutsCardGrapeTitle = String(localized: "Tempranillo", bundle: .module)
    var learnShortcutsCardGrapeSubtitle = String(localized: "Spain's great red", bundle: .module)
    var learnShortcutsCardLessonEyebrow = String(localized: "A lesson", bundle: .module)
    var learnShortcutsCardLessonTitle = String(localized: "Organic, biodynamic and natural", bundle: .module)
    var learnShortcutsCardLessonSubtitle = String(localized: "What the labels really mean", bundle: .module)
    var learnShortcutsCardStartTitle = String(localized: "Start", bundle: .module)
    var winesForPalateCardSectionTitle = String(localized: "Wines for your palate", bundle: .module)
    var wordOfTheDayCardSectionTitle = String(localized: "Word of the day", bundle: .module)
    var chooseYourWineCardSectionTitle = String(localized: "Choose your wine", bundle: .module)
    var chooseYourWineCardPrompt = String(localized: "Tell us what you feel like tonight.", bundle: .module)
    var chooseYourWineCardTypeTitle = String(localized: "Type", bundle: .module)
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
    var wineRowAxisSymbol = "✷"
    var wineRowChevronIcon = "chevron.right"
    var wineFactsOriginTitle = String(localized: "Origin", bundle: .module)
    var wineFactsAppellationTitle = String(localized: "Appellation", bundle: .module)
    var wineFactsGrapesTitle = String(localized: "Grapes", bundle: .module)
    var wineFactsNotesTitle = String(localized: "Notes", bundle: .module)
    var wineFactsServingTitle = String(localized: "Serve at", bundle: .module)
    var wineFactsVintageTitle = String(localized: "Vintage", bundle: .module)

    var palateMatchTitle = String(localized: "With your palate", bundle: .module)
    var palateMatchCaption = String(localized: "match with your map", bundle: .module)
    var plateImage: Image { UVVAIllustration.plate }
    var anywhere = String(localized: "Anywhere", bundle: .module)
    var maximumNotes = 3
    var wineTypes: [String] = [
        String(localized: "Red", bundle: .module),
        String(localized: "White", bundle: .module),
        String(localized: "Rosé", bundle: .module),
        String(localized: "Sparkling", bundle: .module),
        String(localized: "Sweet", bundle: .module),
        String(localized: "Fortified", bundle: .module)
    ]
    var regions: [String] { [anywhere] + [
        String(localized: "Portugal", bundle: .module),
        String(localized: "France", bundle: .module),
        String(localized: "Italy", bundle: .module),
        String(localized: "Spain", bundle: .module),
        String(localized: "United States", bundle: .module),
        String(localized: "Argentina", bundle: .module),
        String(localized: "Chile", bundle: .module),
        String(localized: "Germany", bundle: .module),
        String(localized: "Austria", bundle: .module),
        String(localized: "Australia", bundle: .module),
        String(localized: "New Zealand", bundle: .module),
        String(localized: "South Africa", bundle: .module)
    ] }
    var wineNotes: [String] = [
        String(localized: "Citrus", bundle: .module),
        String(localized: "Orchard fruit", bundle: .module),
        String(localized: "Tropical", bundle: .module),
        String(localized: "Red fruit", bundle: .module),
        String(localized: "Dark fruit", bundle: .module),
        String(localized: "Floral", bundle: .module),
        String(localized: "Herbal", bundle: .module),
        String(localized: "Spiced", bundle: .module),
        String(localized: "Mineral", bundle: .module),
        String(localized: "Earthy", bundle: .module),
        String(localized: "Toasty", bundle: .module)
    ]

    func mapChange(axis: PalateAxis, delta: Double) -> String {
        delta >= 0
            ? String(localized: "Your last wine raised your \(axis.rawValue) notes.", bundle: .module)
            : String(localized: "Your last wine lowered your \(axis.rawValue) notes.", bundle: .module)
    }

    func compatibility(_ value: Int) -> String { "\(value)%" }
    func friendMatch(_ name: String) -> String { String(localized: "match with \(name)", bundle: .module) }
    func lessonTotal(_ count: Int) -> String { "/\(count)" }
}

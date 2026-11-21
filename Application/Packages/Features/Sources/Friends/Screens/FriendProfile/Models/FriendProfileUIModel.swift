import CoreUI
import Foundation

public struct FriendProfileUIModel {
    var tab: FriendProfileTab = .map
    var name = ""
    /// "Marina": the legend and "Reading by reading" name her by her first name.
    var firstName = ""
    var signature = ""
    var compatibilityText = ""

    // FRI-R11 · Map
    var mapTitle = ""
    var friendChart: [Double] = []
    var strongAxes: Set<Int> = []
    var caption = ""
    var readings: [FriendReadingUIModel] = []
    /// "Picks for Marina", over the second panel.
    var giftTitle = ""
    /// Nil while they are looked up; empty when the catalog has none.
    var giftWines: [WineCardRowUIModel]?
    /// Friend Wine over the Map, when a wine is open.
    var friendWine: FriendWineUIModel?
    /// FRI-R12a: the label scanner, while it is open; `canScan` when the app gave one.
    var scanner: NewNoteViewModel?
    var canScan = false

    // FRI-R12 · Compatibility
    var matchTitle = ""
    /// "of your palate map matches Marina", beside `compatibilityText` in large.
    var matchCaption = ""
    var userChart: [Double] = []
    var overlapPhrase = ""
    var compareRows: [FriendCompareRowUIModel] = []

    // FRI-R13, R15 · Set a table
    /// FRI-R15a: "Set the perfect dinner" opens the table in a sheet: the menu, how to make it, how to share it.
    var isTableOpen = false
    /// FRI-R13a: the choices of the dinner.
    var dinner = DinnerUIModel()
    var dinnerTitle = ""
    /// "You & Marina", on the menu card.
    var guestsText = ""
    /// Nil while the bottles are worked out.
    var bottles: [TableBottleUIModel]?
    /// FRI-R12 "Open this together": the same bottles as rows of the wine card; nil while they are worked out.
    var togetherWines: [WineCardRowUIModel]?
    /// The dish of each course and how to make it; nil while the bottles are worked out.
    var recipes: [TableRecipeUIModel]?
    /// Nil until the bottles are there (FRI-R21).
    var share: TableShareUIModel?
    var isSharing = false

    var isConfirmingRemoval = false
    var removeTitle = ""
    var removeBody = ""
    var resources = FriendProfileResourcesUIModel()
}

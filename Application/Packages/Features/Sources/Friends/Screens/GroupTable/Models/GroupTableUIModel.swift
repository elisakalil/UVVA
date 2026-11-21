import CoreUI
import Foundation

public struct GroupTableUIModel {
    /// "You, Marina, Bia and Rui".
    var membersText = ""
    /// The names on the chips, the user last.
    var memberNames: [String] = []
    /// "4 maps · one bottle".
    var mapsText = ""
    var matchTitle = ""
    /// The large "71%" and, beside it, "match across all 4 palate maps at the table".
    var matchValueText = ""
    var matchCaption = ""
    var phrase = ""
    var averageChart: [Double] = []
    var boldestChart: [Double] = []
    var isReadingsExpanded = false
    var readings: [AxisSpreadRowUIModel] = []
    var dinnerTitle = ""
    /// "The 4 of you", on the menu card.
    var guestsText = ""
    var footerText = ""
    /// Nil while the bottles are worked out.
    var bottles: [TableBottleUIModel]?
    /// "Open this together": the same bottles as rows of the wine card; nil while they are worked out.
    var togetherWines: [WineCardRowUIModel]?

    // FRI-R13, R15 · Set a table, as on a friend
    /// FRI-R13a: the choices of the dinner.
    var dinner = DinnerUIModel()
    /// FRI-R15a: "Set the perfect dinner" opens the table in a sheet: the menu, how to make it, how to share it.
    var isTableOpen = false
    /// The dish of each course and how to make it; nil while the bottles are worked out.
    var recipes: [TableRecipeUIModel]?

    /// Friend Wine, read on every map at the table, when a bottle or a scanned wine is open.
    var friendWine: FriendWineUIModel?
    /// The label scanner, while it is open; `canScan` when the app gave one.
    var scanner: NewNoteViewModel?
    var canScan = false
    /// Nil until the bottles are there (FRI-R21, R22).
    var share: TableShareUIModel?
    var isSharing = false
    var resources = GroupTableResourcesUIModel()
}

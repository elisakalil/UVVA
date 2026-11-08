import Foundation

public struct FriendProfileUIModel {
    var tab: FriendProfileTab = .palate
    var name = ""
    var signature = ""
    var compatibilityText = ""

    // FRI-R11 · Palate
    var palateTitle = ""
    var friendChart: [Double] = []
    var strongAxes: Set<Int> = []
    var caption = ""
    var readings: [FriendReadingUIModel] = []

    // FRI-R12 · Compatibility
    var matchTitle = ""
    var userChart: [Double] = []
    var overlapPhrase = ""

    // FRI-R13, R15 · Table
    var dinnerTitle = ""
    /// Nil while the bottles are worked out.
    var bottles: [TableBottleUIModel]?
    /// Nil until the bottles are there (FRI-R21).
    var share: TableShareUIModel?
    var isSharing = false

    var isConfirmingRemoval = false
    var removeTitle = ""
    var removeBody = ""
    var resources = FriendProfileResourcesUIModel()
}

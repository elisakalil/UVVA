import Foundation

public struct GroupTableUIModel {
    /// "You, Marina, Bia and Rui".
    var membersText = ""
    var matchTitle = ""
    var phrase = ""
    var averageChart: [Double] = []
    var boldestChart: [Double] = []
    var isReadingsExpanded = false
    var readings: [AxisSpreadRowUIModel] = []
    var dinnerTitle = ""
    var footerText = ""
    /// Nil while the bottles are worked out.
    var bottles: [TableBottleUIModel]?
    /// Nil until the bottles are there (FRI-R21, R22).
    var share: TableShareUIModel?
    var isSharing = false
    var resources = GroupTableResourcesUIModel()
}

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
    var resources = GroupTableResourcesUIModel()
}

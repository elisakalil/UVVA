import Core
import Foundation
import Match

/// The group table from every map at it, the user's first. Pure (FRI §3: the numbers come from `TableMatch`).
struct GroupTablePresentationBuilder {
    var userMap: PalateMap
    var friends: [Friend]
    var bottles: [TableBottle]?
    var resources: GroupTableResourcesUIModel

    private var maps: [PalateMap] { [userMap] + friends.map(\.map) }
    private var count: Int { maps.count }
    private var shared: [PalateAxis] { TableMatch.sharedAxes(maps) }

    func build(into model: inout GroupTableUIModel) {
        model.membersText = membersText
        model.matchTitle = resources.match(TableMatch.tableCompatibility(maps), count)
        model.phrase = phrase
        model.averageChart = TableMatch.crossed(maps).chartValues
        model.boldestChart = TableMatch.boldest(maps).chartValues
        model.readings = readings
        model.dinnerTitle = resources.dinnerTitle(count)
        model.footerText = resources.footer(count)
        model.bottles = bottles.map { TableBottlesBuilder(resources: resources.table).rows($0, shared: shared) }
    }

    /// "You, Marina, Bia and Rui".
    var membersText: String {
        let names = [resources.youText] + friends.map(\.name)
        return resources.table.joined(names.dropLast().joined(separator: ", "), names[names.count - 1])
    }

    /// FRI-R19: "You all want …", or "Nothing lines up across all [n] …".
    var phrase: String {
        shared.isEmpty ? resources.nothingLinesUp(count)
                       : resources.allWant(TableBottlesBuilder.list(shared, resources: resources.table))
    }

    /// FRI-R19 "Reading by reading": every axis, its label, a line, and the range at the table.
    var readings: [AxisSpreadRowUIModel] {
        PalateAxis.allCases.map { axis in
            let spread = TableMatch.axisSpread(maps, axis)
            let range = TableMatch.range(maps, axis)
            return AxisSpreadRowUIModel(name: axis.label, spreadText: resources.spread(spread),
                                        phrase: resources.spreadPhrase(spread),
                                        rangeText: resources.range(Self.number(range.lowerBound), Self.number(range.upperBound)))
        }
    }

    /// 6 → "6", 6.5 → "6.5".
    static func number(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
    }
}

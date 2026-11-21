import Core
import Foundation
import Match

/// The group table from every map at it, the user's first. Pure (FRI §3: the numbers come from `TableMatch`).
struct GroupTablePresentationBuilder {
    var userMap: PalateMap
    var userName = ""
    var friends: [Friend]
    var bottles: [TableBottle]?
    var resources: GroupTableResourcesUIModel

    private var maps: [PalateMap] { [userMap] + friends.map(\.map) }
    private var count: Int { maps.count }
    private var shared: [PalateAxis] { TableMatch.sharedAxes(maps) }

    func build(into model: inout GroupTableUIModel) {
        let compatibility = TableMatch.tableCompatibility(maps)
        model.membersText = membersText
        model.memberNames = friends.map(\.name) + [resources.youText]
        model.mapsText = resources.maps(count)
        model.matchTitle = resources.match(compatibility, count)
        model.matchValueText = "\(compatibility)%"
        model.matchCaption = resources.matchCaption(count)
        model.phrase = phrase
        model.averageChart = TableMatch.crossed(maps).chartValues
        model.boldestChart = TableMatch.boldest(maps).chartValues
        model.readings = readings
        model.dinnerTitle = resources.dinnerTitle(count)
        model.guestsText = resources.guests(count)
        model.footerText = resources.footer(count)
        model.share = bottles.flatMap { $0.isEmpty ? nil : TableShareBuilder(friendNames: friends.map(\.name), userName: userName,
                                                                              bottles: $0, resources: resources.table).build() }
        model.bottles = bottles.map { TableBottlesBuilder(resources: resources.table).rows($0, shared: shared) }
        model.togetherWines = bottles.map { $0.map { dinnerBuilder.wineRow($0.wine, axis: $0.axis) } }
        model.recipes = bottles.map { $0.map(dinnerBuilder.recipe) }
    }

    private var dinnerBuilder: TableDinnerBuilder { TableDinnerBuilder(resources: resources.dinner, table: resources.table) }

    /// FRI-R13a: the choices of the dinner, as chips, as on a friend.
    func dinner(_ preferences: DinnerPreferences, now: Date, isStale: Bool) -> DinnerUIModel {
        dinnerBuilder.dinner(preferences, now: now, isStale: isStale)
    }

    /// Friend Wine: a bottle of "Open this together" or a scanned wine, read on every map at the table.
    func friendWine(_ wine: Wine, sending: FriendWinePresentationBuilder.Sending) -> FriendWineUIModel {
        // "Marina", from "Marina Lopes", as on a friend.
        let names = friends.map { $0.name.split(separator: " ").first.map(String.init) ?? $0.name }
        let reader = FriendWinePresentationBuilder.Reader.table(friendNames: names, userMap: userMap,
                                                                friendMaps: friends.map(\.map))
        return FriendWinePresentationBuilder(wine: wine, reader: reader, sending: sending).build()
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
        let middles = TableMatch.crossed(maps).chartValues
        let top = PalateMap.range.upperBound
        return PalateAxis.allCases.enumerated().map { index, axis in
            let spread = TableMatch.axisSpread(maps, axis)
            let range = TableMatch.range(maps, axis)
            return AxisSpreadRowUIModel(name: axis.label, spreadText: resources.spread(spread),
                                        phrase: resources.spreadPhrase(spread),
                                        rangeText: resources.range(Self.number(range.lowerBound), Self.number(range.upperBound)),
                                        low: range.lowerBound / top, high: range.upperBound / top,
                                        middle: middles[index], isClose: spread == .same || spread == .closest)
        }
    }

    /// 6 → "6", 6.5 → "6.5".
    static func number(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
    }
}

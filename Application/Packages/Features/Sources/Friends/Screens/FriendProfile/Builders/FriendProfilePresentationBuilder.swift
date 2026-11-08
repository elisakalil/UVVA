import Core
import Foundation
import Match

/// A friend's three tabs from the two maps. Pure (FRI §3: the numbers come from `TableMatch`).
struct FriendProfilePresentationBuilder {
    var friend: Friend
    var userMap: PalateMap
    var bottles: [TableBottle]?
    var resources: FriendProfileResourcesUIModel

    private var reading: MapReading { MapReading(map: friend.map) }
    private var compatibility: Int { TableMatch.compatibility(userMap, friend.map) }
    var shared: [PalateAxis] { TableMatch.sharedAxes([userMap, friend.map]) }

    func build(into model: inout FriendProfileUIModel) {
        model.name = friend.name
        model.signature = reading.signature
        model.compatibilityText = "\(compatibility)%"
        model.palateTitle = resources.palateTitle(friend.name)
        model.friendChart = friend.map.chartValues
        model.strongAxes = Set(reading.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) })
        model.caption = reading.shortCaption
        model.readings = readings
        model.matchTitle = resources.matches(compatibility, friend.name)
        model.userChart = userMap.chartValues
        model.overlapPhrase = overlapPhrase
        model.dinnerTitle = resources.dinnerTitle(friend.name)
        model.bottles = bottles.map { TableBottlesBuilder(resources: resources.table).rows($0, shared: shared) }
        model.removeTitle = resources.removeTitle(friend.name)
        model.removeBody = resources.removeBody(friend.name)
    }

    /// FRI-R11: every axis, its pips and its word; the three leaders stronger.
    var readings: [FriendReadingUIModel] {
        let leaders = reading.leaders(3)
        return PalateAxis.allCases.map { axis in
            let level = MapReading.level(friend.map[axis])
            return FriendReadingUIModel(name: axis.label, level: level, word: MapReading.levelWord(level),
                                        isStrong: leaders.contains(axis))
        }
    }

    /// FRI-R12: "You both want acidity, fruit and spice in a glass.", or "You barely overlap…".
    var overlapPhrase: String {
        shared.isEmpty ? resources.noOverlapText
                       : resources.bothWant(TableBottlesBuilder.list(shared, resources: resources.table))
    }
}

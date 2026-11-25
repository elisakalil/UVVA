import Core
import Foundation
import Match

/// A friend's three tabs from the two maps. Pure (FRI §3: the numbers come from `TableMatch`).
struct FriendProfilePresentationBuilder {
    var friend: Friend
    var userMap: PalateMap
    var userName = ""
    var bottles: [TableBottle]?
    /// The catalog's bottles closest to the friend's map (FRI-R11); nil while they are looked up.
    var giftWines: [Wine]?
    var resources: FriendProfileResourcesUIModel

    private var reading: MapReading { MapReading(map: friend.map) }
    /// "Beatriz", from "Beatriz Damas": the titles of the Map cards.
    var firstName: String { friend.name.split(separator: " ").first.map(String.init) ?? friend.name }
    private var compatibility: Int { TableMatch.compatibility(userMap, friend.map) }
    var shared: [PalateAxis] { TableMatch.sharedAxes([userMap, friend.map]) }

    func build(into model: inout FriendProfileUIModel) {
        model.name = friend.name
        model.firstName = firstName
        model.signature = reading.signature
        model.compatibilityText = "\(compatibility)%"
        model.mapTitle = resources.mapTitle(firstName)
        model.friendChart = friend.map.chartValues
        model.strongAxes = Set(reading.highlighted.compactMap { PalateAxis.allCases.firstIndex(of: $0) })
        model.caption = reading.shortCaption
        model.readings = readings
        model.giftTitle = resources.giftTitle(firstName)
        model.giftWines = giftWines.map(giftRows)
        model.matchTitle = resources.matches(compatibility, friend.name)
        model.matchCaption = resources.matchCaption(friend.name)
        model.userChart = userMap.chartValues
        model.overlapPhrase = overlapPhrase
        model.compareRows = compareRows
        model.dinnerTitle = resources.dinnerTitle(friend.name)
        model.guestsText = resources.guests(friend.name)
        model.bottles = bottles.map { TableBottlesBuilder(resources: resources.table).rows($0, shared: shared) }
        model.togetherWines = bottles.map { $0.map { dinnerBuilder.wineRow($0.wine, axis: $0.axis) } }
        model.recipes = bottles.map { $0.map(dinnerBuilder.recipe) }
        model.share = bottles.flatMap { $0.isEmpty ? nil : TableShareBuilder(friendNames: [friend.name], userName: userName,
                                                                              bottles: $0, resources: resources.table).build() }
        model.removeTitle = resources.removeTitle(friend.name)
        model.removeBody = resources.removeBody(friend.name)
    }

    /// FRI-R11: every axis, its pips and its word; the three leaders stronger.
    var readings: [FriendReadingUIModel] {
        let leaders = reading.leaders(3)
        return PalateAxis.allCases.map { axis in
            let level = MapReading.level(friend.map, axis)
            return FriendReadingUIModel(name: axis.label, level: level, word: MapReading.levelWord(level, on: axis),
                                        isStrong: leaders.contains(axis))
        }
    }

    /// FRI-R11 "Picks for [name]": each bottle with the leading reading of the friend's map it stands out
    /// on most, and how strong the wine is on it.
    func giftRows(_ wines: [Wine]) -> [WineCardRowUIModel] {
        let leaders = reading.leaders(3)
        return wines.map { wine in
            let standsOut = WineRuler.positions(of: wine.profile)
            return dinnerBuilder.wineRow(wine, axis: leaders.max { standsOut[$0] < standsOut[$1] } ?? friend.map.ranked[0])
        }
    }

    private var dinnerBuilder: TableDinnerBuilder { TableDinnerBuilder(resources: resources.dinner, table: resources.table) }

    /// FRI-R13a: the choices of the dinner, as chips.
    func dinner(_ preferences: DinnerPreferences, now: Date, isStale: Bool) -> DinnerUIModel {
        dinnerBuilder.dinner(preferences, now: now, isStale: isStale)
    }

    /// Friend Wine: a wine of the friend's Map against the friend's map (FRI-R11a), or a bottle of "Open this
    /// together" or a scanned one against the two maps (FRI-R12a).
    func friendWine(_ wine: Wine, isForBoth: Bool, sending: FriendWinePresentationBuilder.Sending,
                    isInCellar: Bool = false) -> FriendWineUIModel {
        let reader: FriendWinePresentationBuilder.Reader = isForBoth
            ? .both(friendName: firstName, userMap: userMap, friendMap: friend.map)
            : .friend(name: firstName, map: friend.map)
        return FriendWinePresentationBuilder(wine: wine, reader: reader, sending: sending, isInCellar: isInCellar).build()
    }

    /// FRI-R12 "Reading by reading": both readings of every axis on one line, and how far apart they are.
    var compareRows: [FriendCompareRowUIModel] {
        PalateAxis.allCases.map { axis in
            let spread = TableMatch.axisSpread([userMap, friend.map], axis)
            return FriendCompareRowUIModel(name: axis.label, verdict: resources.verdict(spread),
                                           mineLevel: MapReading.level(userMap, axis),
                                           theirsLevel: MapReading.level(friend.map, axis), isSame: spread == .same)
        }
    }

    /// FRI-R12: "You both want acidity, fruit and spice in a glass.", or "You barely overlap…".
    var overlapPhrase: String {
        shared.isEmpty ? resources.noOverlapText
                       : resources.bothWant(TableBottlesBuilder.list(shared, resources: resources.table))
    }
}

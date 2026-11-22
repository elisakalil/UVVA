import Core
import CoreUI
import Foundation
import Match

/// Friend Wine from the wine and the map(s) it is read against (FRI-R11a, R12a). Pure: the match comes from
/// `Similarity` and `WineFit` (Match); the facts are laid out as on every wine sheet (CoreUI).
struct FriendWinePresentationBuilder {
    /// Whose map the wine is read against.
    enum Reader {
        /// A wine of the friend's Map: the friend's map alone (FRI-R11a).
        case friend(name: String, map: PalateMap)
        /// A wine scanned on Compatibility: the two maps together, and each one's match (FRI-R12a).
        case both(friendName: String, userMap: PalateMap, friendMap: PalateMap)
        /// A wine a friend sent: the user's own map, as on the Home (FRI-R11c).
        case you(senderName: String, map: PalateMap)
        /// A wine scanned or opened on a group table: every map at it together, and each one's match (FRI-R19).
        case table(friendNames: [String], userMap: PalateMap, friendMaps: [PalateMap])
    }

    /// Where the wine is, and so what its foot does.
    enum Sending: Equatable {
        case idle, sending, sent, failed
    }

    var wine: Wine
    var reader: Reader
    /// A wine to send (the friend's Map, a scan): how far the sending got. Ignored for a wine received.
    var sending = Sending.idle
    /// A wine received: already in the Cellar.
    var isInCellar = false
    var now = Date()
    var resources = FriendWineResourcesUIModel()
    var paper = NotePaperResources()

    /// The map the match is read on: the friend's, or the middle of the two (`TableMatch.crossed`).
    var map: PalateMap {
        switch reader {
        case let .friend(_, map): map
        case let .both(_, userMap, friendMap): TableMatch.crossed([userMap, friendMap])
        case let .you(_, map): map
        case let .table(_, userMap, friendMaps): TableMatch.crossed([userMap] + friendMaps)
        }
    }

    /// The maps at a group table, the user's included.
    private var tableCount: Int {
        if case let .table(_, _, friendMaps) = reader { friendMaps.count + 1 } else { 0 }
    }

    /// "Marina's map", "your two maps", "your 4 maps".
    private var mapName: String {
        switch reader {
        case let .friend(name, _): resources.friendMap(name)
        case .both: resources.yourTwoMapsText
        case .you: resources.yourMapText
        case .table: resources.yourMaps(tableCount)
        }
    }

    /// "Marina usually drinks", "you two usually drink", "the 4 of you usually drink".
    private var drinker: String {
        switch reader {
        case let .friend(name, _): resources.friendDrinks(name)
        case .both: resources.youTwoDrinkText
        case .you: resources.youDrinkText
        case .table: resources.youAllDrink(tableCount)
        }
    }

    func build() -> FriendWineUIModel {
        var content = WineSheetContent(
            title: wine.name, eyebrow: wine.producer,
            percentage: "\(Similarity.percent(wine.profile, map))%",
            percentageCaption: resources.matchCaption(mapName),
            sharedLine: sharedLine, apartLine: apartLine, facts: facts,
            pairings: wine.pairings.isEmpty ? nil : wine.pairings.joined(separator: ", "),
            servingTemperature: wine.serving.map { "\($0.lowerBound)–\($0.upperBound) °C" },
            howToServe: (wine.howToServe ?? "").isEmpty ? nil : wine.howToServe,
            profile: wine.profile, palate: map, certificate: WineCertificateUIModel(wine: wine))
        content.findURL = WineSearch.url(for: wine)
        let who: String
        let legend: String
        switch reader {
        case let .friend(name, _):
            who = name
            legend = resources.friendMap(name)
        case .both:
            who = resources.youTwoText
            legend = resources.yourTwoMapsLegend
        case .you:
            who = resources.youText.lowercased()
            legend = resources.yourMapLegend
        case .table:
            who = resources.theFewOfYou(tableCount)
            legend = resources.yourMapsLegend(tableCount)
        }
        let strings = WineSheetStrings(
            findWine: resources.findWineText, pairings: resources.pairingsText, serve: resources.serveText,
            wineMap: resources.wineMapText, comparison: resources.comparison(who),
            wineLegend: resources.wineLegendText, palateLegend: legend, overlapLegend: resources.overlapLegendText)
        return FriendWineUIModel(id: wine.id, content: content, strings: strings, people: people, note: note,
                                 footer: footer, resources: resources)
    }

    /// "Marina sent you this wine", over a wine received.
    private var note: String? {
        if case let .you(sender, _) = reader { resources.sentYou(sender) } else { nil }
    }

    /// Send the wine to the friend, or to everyone at a group table; a wine received goes to the Cellar instead.
    private var footer: FriendWineUIModel.Footer {
        switch reader {
        case .you: return .addToCellar(isInCellar: isInCellar)
        case let .friend(name, _), let .both(name, _, _):
            return send(to: resources.sendTo(name), sent: resources.sentTo(name))
        case .table:
            return send(to: resources.sendToTableText, sent: resources.sentToTableText)
        }
    }

    private func send(to sendTitle: String, sent sentTitle: String) -> FriendWineUIModel.Footer {
        switch sending {
        case .idle: .send(title: sendTitle, isEnabled: true, failed: nil)
        case .sending: .send(title: resources.sendingText, isEnabled: false, failed: nil)
        case .sent: .send(title: sentTitle, isEnabled: false, failed: nil)
        case .failed: .send(title: sendTitle, isEnabled: true, failed: resources.sendFailedText)
        }
    }

    /// A scanned wine: "You 68%" and "Marina 81%", and everyone else at a group table.
    var people: [FriendWineUIModel.PersonMatch] {
        let names: [String]
        let maps: [PalateMap]
        switch reader {
        case let .both(friendName, userMap, friendMap):
            names = [resources.youText, friendName]
            maps = [userMap, friendMap]
        case let .table(friendNames, userMap, friendMaps):
            names = [resources.youText] + friendNames
            maps = [userMap] + friendMaps
        case .friend, .you:
            return []
        }
        return zip(names, maps).map { .init(name: $0, percentage: "\(Similarity.percent(wine.profile, $1))%") }
    }

    private var fit: WineFit { WineFit(wine: wine.profile, map: map) }

    /// "High in acidity and fruit, like Marina's map."
    var sharedLine: String {
        let fit = fit
        let both = fit.shared.map { $0.label.lowercased() }
        switch both.count {
        case 2: return resources.highInBoth(both[0], both[1], mapName)
        case 1: return resources.highIn(both[0], mapName)
        default: break
        }
        switch fit.mapHighs.count {
        case 0: return fit.wineHasHigh ? resources.bolder(mapName) : resources.quiet(mapName)
        case 1: return resources.notHighIn(fit.mapHighs[0].label.lowercased(), mapName)
        default: return resources.different(mapName)
        }
    }

    /// "More oak than Marina usually drinks."
    var apartLine: String {
        guard let far = fit.apart else { return resources.close(mapName) }
        let axis = far.label.lowercased()
        return wine.profile[far] > map[far] ? resources.more(axis, drinker) : resources.less(axis, drinker)
    }

    /// Origin, producer, style, vintage, grapes and notes, as on every wine sheet.
    private var facts: [WineSheetContent.Fact] {
        [
            .init(label: paper.originText, value: wine.origin),
            .init(label: paper.producerText, value: wine.producer),
            .init(label: paper.styleText, value: paper.type(wine.type)),
            .init(label: paper.vintageText, value: paper.vintageLine(wine.vintage, now: now)),
            .init(label: paper.grapesText, value: wine.grapes.joined(separator: ", ")),
            .init(label: paper.notesText, value: WineCatalogText.notes(wine.note))
        ]
    }
}

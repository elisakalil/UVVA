import Core
import CoreUI
import Foundation

/// What the wine sheet shows about one wine, and where it was opened from (HOME-R28a).
struct WineDetailUIModel: Equatable {
    enum Source: Equatable {
        /// A row of "Wines for your palate" (HOME-R22): the wine stands for one axis.
        case palate(PalateWineSuggestion)
        /// A result of "Choose your wine" (HOME-R28): which one of how many, for the chosen type.
        case discovery(WineDiscovery.Direction, index: Int, count: Int)
    }

    struct Fact: Equatable, Identifiable {
        var label: String
        var value: String
        var id: String { label }
    }

    let wine: Wine
    let source: Source
    let palateMap: PalateMap
    /// The wines the user rated: the grape and region lines wait for it.
    var history: TasteHistory?
    var now = Date()
    var resources = HomeResourcesUIModel()

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wine == rhs.wine && lhs.source == rhs.source && lhs.palateMap == rhs.palateMap && lhs.history == rhs.history
    }

    private var match: PalateMatchUIModel { PalateMatchUIModel(wine: wine.profile, palate: palateMap) }

    // MARK: Header

    /// "SOALHEIRO", under the name; a result of the form reads "Your pick · Soalheiro".
    var eyebrow: String {
        switch source {
        case .palate: wine.producer
        case .discovery:
            wine.producer.isEmpty ? resources.wineDetailPickTitle : "\(resources.wineDetailPickTitle) · \(wine.producer)"
        }
    }

    var title: String { wine.name }

    /// The longer the name, the smaller it is drawn, so it holds in two lines at most.
    var titleSize: CGFloat {
        switch title.count {
        case 23...: 24
        case 15...: 29
        default: 36
        }
    }

    /// "2 of 5 red wines for your choices", under a result of the form.
    var resultCount: String? {
        guard case let .discovery(_, index, count) = source, count > 0 else { return nil }
        let type = resources.wineFilterLabel(wine.type).lowercased()
        return count == 1
            ? String(localized: "The only \(type) for your choices", bundle: .module)
            : String(localized: "\(index + 1) of \(count) \(type) wines for your choices", bundle: .module)
    }

    var hasAnotherResult: Bool {
        if case let .discovery(_, _, count) = source { count > 1 } else { false }
    }

    // MARK: With your palate

    /// The match with the map, as everywhere else, "Surprise me" included: a surprise reads low, and says so.
    var percentage: String { "\(match.percent)%" }
    var percentageCaption: String { resources.palateMatchCaption }
    var matchPercent: Int { match.percent }

    /// The grape, the region and why it suits the map, as on a note; empty until the Cellar is read.
    var insights: [NoteInsightUIModel] {
        history.map { NoteInsightUIModel.lines(wine: wine, palate: palateMap, history: $0) } ?? []
    }
    var sharedLine: String { match.shared }
    var apartLine: String { match.apart }

    // MARK: The wine

    var facts: [Fact] {
        [
            Fact(label: resources.wineFactsOriginTitle, value: wine.originLine),
            Fact(label: resources.wineDetailProducerTitle, value: wine.producer),
            Fact(label: resources.wineDetailStyleTitle, value: resources.wineFilterLabel(wine.type)),
            Fact(label: resources.wineFactsVintageTitle, value: vintageLine),
            Fact(label: resources.wineFactsGrapesTitle, value: wine.grapes.joined(separator: ", ")),
            Fact(label: resources.wineFactsNotesTitle, value: WineCatalogText.notes(wine.note))
        ]
    }

    var pairings: String? {
        wine.pairings.isEmpty ? nil : wine.pairings.map(WineCatalogText.editorial).joined(separator: ", ")
    }

    /// "2023 · 3 years", or "Non-vintage".
    var vintageLine: String {
        guard let vintage = wine.vintage else { return resources.wineDetailNonVintage }
        return WineFactsUIModel(wine: wine, now: now, resources: resources).vintageLine(vintage)
    }

    /// "8–10 °C", the first line of "How to serve".
    var servingTemperature: String? {
        wine.serving.map { "\($0.lowerBound)–\($0.upperBound) °C" }
    }

    var howToServe: String? {
        guard let line = wine.howToServe, !line.isEmpty else { return nil }
        return line
    }

    /// "How to serve" shows with the temperature, the line on serving, or both.
    var showsServing: Bool { servingTemperature != nil || howToServe != nil }
}

/// The sheet the Home has open over its cards, if any.
enum WineSheetModel: Identifiable, Equatable {
    case palate(PalateWineSuggestion)
    case discovery(suggestions: WineList, direction: WineDiscovery.Direction)

    var id: String {
        switch self {
        case let .palate(suggestion): "palate.\(suggestion.axis.rawValue).\(suggestion.wine.id)"
        case let .discovery(suggestions, direction): "discovery.\(direction).\(suggestions.id)"
        }
    }
}

import Core
import Foundation

/// What the wine sheet shows of one wine (HOME-R28a), drawn the same on the Home and on a saved note of the Cellar:
/// the name and producer, how it sits with the map, its facts, where to find it, its pairings, how to serve it,
/// its axes and its two maps. Plain words in, so each screen keeps its own.
public struct WineSheetContent: Equatable {
    public struct Fact: Equatable, Identifiable {
        public var label: String
        public var value: String
        /// In a second column beside the one before it: Vintage beside Origin, Grape & notes beside Style.
        public var besidePrevious: Bool
        public var id: String { label }

        public init(label: String, value: String, besidePrevious: Bool = false) {
            self.label = label
            self.value = value
            self.besidePrevious = besidePrevious
        }
    }

    public var title: String
    /// Under the name: the producer, or "Your pick · Producer".
    public var eyebrow: String
    /// "72%", with what it means; nil without a map.
    public var percentage: String?
    public var percentageCaption: String
    public var sharedLine: String?
    public var apartLine: String?
    public var facts: [Fact]
    public var pairings: String?
    /// "14–16 °C", the first line of "How to serve".
    public var servingTemperature: String?
    public var howToServe: String?
    public var profile: PalateMap
    public var palate: PalateMap?
    /// "Find the wine": a search for it (HOME-R09a); set by the screens that open it themselves.
    public var findURL: URL?

    public init(title: String, eyebrow: String, percentage: String?, percentageCaption: String, sharedLine: String?,
                apartLine: String?, facts: [Fact], pairings: String?, servingTemperature: String?, howToServe: String?,
                profile: PalateMap, palate: PalateMap?) {
        self.title = title
        self.eyebrow = eyebrow
        self.percentage = percentage
        self.percentageCaption = percentageCaption
        self.sharedLine = sharedLine
        self.apartLine = apartLine
        self.facts = facts
        self.pairings = pairings
        self.servingTemperature = servingTemperature
        self.howToServe = howToServe
        self.profile = profile
        self.palate = palate
    }

    /// The longer the name, the smaller it is drawn, so it holds in two lines at most.
    public var titleSize: CGFloat {
        switch title.count {
        case 23...: 24
        case 15...: 29
        default: 36
        }
    }

    public var showsServing: Bool { servingTemperature != nil || howToServe != nil }
}

/// The titles of the wine sheet. The Home passes its own; the Cellar uses these.
public struct WineSheetStrings {
    public var findWine: String
    public var pairings: String
    public var serve: String
    public var wineMap: String
    public var comparison: String
    public var wineLegend: String
    public var palateLegend: String
    public var overlapLegend: String

    public init(findWine: String, pairings: String, serve: String, wineMap: String, comparison: String,
                wineLegend: String, palateLegend: String, overlapLegend: String) {
        self.findWine = findWine
        self.pairings = pairings
        self.serve = serve
        self.wineMap = wineMap
        self.comparison = comparison
        self.wineLegend = wineLegend
        self.palateLegend = palateLegend
        self.overlapLegend = overlapLegend
    }
}

public extension WineSheetContent {
    /// A wine as the wine sheet shows it, in the words of the new note: Origin | Vintage, Style | Grape & notes.
    init(wine: Wine, palate: PalateMap?, now: Date = Date(), resources: NotePaperResources = NotePaperResources()) {
        let match = palate.map { PalateMatchUIModel(wine: wine.profile, palate: $0) }
        var facts: [Fact] = []
        if !wine.origin.isEmpty { facts.append(Fact(label: resources.originText, value: wine.origin)) }
        facts.append(Fact(label: resources.vintageText, value: resources.vintageLine(wine.vintage, now: now),
                          besidePrevious: true))
        facts.append(Fact(label: resources.styleText, value: resources.type(wine.type)))
        let grapeAndNotes = [wine.grapes.joined(separator: ", "), wine.note ?? ""].filter { !$0.isEmpty }
        if !grapeAndNotes.isEmpty {
            facts.append(Fact(label: resources.grapeNotesText, value: grapeAndNotes.joined(separator: " · "),
                              besidePrevious: true))
        }
        self.init(title: wine.name, eyebrow: wine.producer, percentage: match?.percentage,
                  percentageCaption: match == nil ? resources.noMapText : resources.matchText,
                  sharedLine: match?.shared, apartLine: match?.apart, facts: facts,
                  pairings: wine.pairings.isEmpty ? nil : wine.pairings.joined(separator: ", "),
                  servingTemperature: wine.serving.map { "\($0.lowerBound)–\($0.upperBound) °C" },
                  howToServe: (wine.howToServe ?? "").isEmpty ? nil : wine.howToServe,
                  profile: wine.profile, palate: palate)
        findURL = WineSearch.url(for: wine)
    }
}

public extension WineSheetStrings {
    /// The titles in the words of the new note.
    init(resources: NotePaperResources = NotePaperResources()) {
        self.init(findWine: resources.findWineText, pairings: resources.pairingsText, serve: resources.serveText,
                  wineMap: resources.wineMapText, comparison: resources.comparisonText,
                  wineLegend: resources.wineText, palateLegend: resources.palateText,
                  overlapLegend: resources.overlapText)
    }
}

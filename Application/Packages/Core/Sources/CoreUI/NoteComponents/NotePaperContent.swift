import Core
import Foundation
import Match

/// The words of the wine on paper, shared by the new note and the saved note of the Cellar.
public struct NotePaperResources {
    public var matchText = String(localized: "match with your map", bundle: .module)
    public var noMapText = String(localized: "Your palate map is unavailable", bundle: .module)
    public var originText = String(localized: "Origin", bundle: .module)
    public var producerText = String(localized: "Producer", bundle: .module)
    public var styleText = String(localized: "Style", bundle: .module)
    public var vintageText = String(localized: "Vintage", bundle: .module)
    public var nonVintageText = String(localized: "Non-vintage", bundle: .module)
    public var serveText = String(localized: "How to serve", bundle: .module)
    public var findWineText = String(localized: "Find the wine", bundle: .module)
    public var grapesText = String(localized: "Grapes", bundle: .module)
    public var notesText = String(localized: "Notes", bundle: .module)
    public var pairingsText = String(localized: "Pairings", bundle: .module)
    public var intensityText = String(localized: "Intensity", bundle: .module)
    public var wineMapText = String(localized: "The map of this wine", bundle: .module)
    public var comparisonText = String(localized: "This wine and you", bundle: .module)
    public var wineText = String(localized: "This wine", bundle: .module)
    public var palateText = String(localized: "Your map", bundle: .module)
    public var overlapText = String(localized: "In common", bundle: .module)
    public var yourNoteText = String(localized: "Your note", bundle: .module)
    public var notYetText = String(localized: "Not yet", bundle: .module)
    public var tastedQuestionText = String(localized: "Have you had this wine?", bundle: .module)
    public var rateAgainQuestionText = String(localized: "Rate it again?", bundle: .module)
    public var drinkAgainText = String(localized: "Would you drink it again?", bundle: .module)
    public var yesText = String(localized: "Yes", bundle: .module)
    public var noText = String(localized: "No", bundle: .module)
    public var maybeText = String(localized: "Maybe", bundle: .module)

    public init() {}

    /// "2023 · 3 years", or "Non-vintage".
    public func vintageLine(_ vintage: Int?, now: Date = Date()) -> String {
        guard let vintage else { return nonVintageText }
        let age = Calendar.current.component(.year, from: now) - vintage
        // The year as text: as a number it would be grouped by the locale, "2 023".
        let year = String(vintage)
        switch age {
        case ..<1: return year
        case 1: return String(localized: "\(year) · 1 year", bundle: .module)
        default: return String(localized: "\(year) · \(age) years", bundle: .module)
        }
    }

    /// "Add to Grapes", the last chip of a section that can grow.
    public var oakText = String(localized: "Time in oak", bundle: .module)

    public func oakAging(_ aging: OakAging) -> String {
        switch aging {
        case .none: String(localized: "No oak", bundle: .module)
        case .upToSix: String(localized: "Up to 6 months", bundle: .module)
        case .sixToTwelve: String(localized: "6–12 months", bundle: .module)
        case .twelveToTwentyFour: String(localized: "12–24 months", bundle: .module)
        case .overTwentyFour: String(localized: "Over 24 months", bundle: .module)
        }
    }

    public func oakWood(_ wood: String) -> String {
        switch wood {
        case "French oak": String(localized: "French oak", bundle: .module)
        case "American oak": String(localized: "American oak", bundle: .module)
        case "Hungarian oak": String(localized: "Hungarian oak", bundle: .module)
        case "Portuguese oak": String(localized: "Portuguese oak", bundle: .module)
        case "Slavonian oak": String(localized: "Slavonian oak", bundle: .module)
        case "Caucasian oak": String(localized: "Caucasian oak", bundle: .module)
        case "Chestnut": String(localized: "Chestnut", bundle: .module)
        case "Acacia": String(localized: "Acacia", bundle: .module)
        default: wood
        }
    }

    /// "12–24 months · French oak, American oak"; nil when the time in wood is unknown.
    public func oak(_ wine: Wine) -> String? {
        guard let aging = wine.oakAging else { return nil }
        let woods = wine.oakWoods.map(oakWood).joined(separator: ", ")
        return [oakAging(aging), woods.isEmpty ? nil : woods].compactMap { $0 }.joined(separator: " · ")
    }

    public func addText(_ section: String) -> String {
        String(localized: "Add to \(section)", bundle: .module)
    }

    public func type(_ type: String) -> String {
        switch type {
        case "Red": String(localized: "Red", bundle: .module)
        case "White": String(localized: "White", bundle: .module)
        case "Rosé": String(localized: "Rosé", bundle: .module)
        case "Sparkling": String(localized: "Sparkling", bundle: .module)
        case "Fortified": String(localized: "Fortified", bundle: .module)
        default: type
        }
    }

    public func verdict(_ verdict: Verdict) -> String {
        switch verdict {
        case .yes: yesText
        case .no: noText
        case .maybe: maybeText
        }
    }
}

/// What the paper shows of one wine, in its order: the name and producer, the match, the facts, how to serve it,
/// the three chip sections, the intensity of each axis and the two maps. Pure: the wine and the map in.
public struct NotePaperContent: Equatable {
    public var title: String
    public var producer: String
    public var origin: String
    /// The certificate card (CELLAR-R30); nil hides it.
    public var certificate: WineCertificateUIModel?
    /// Style and Vintage, under Origin and Producer.
    public var facts: [NoteFactUIModel]
    /// "14–16 °C", then the line on serving; empty when the wine has neither.
    public var serving: String
    /// Nil without a map.
    public var match: Int?
    /// Under the match, as on the wine sheet (HOME-R10b): "High in body, like your map." Nil without a map.
    public var matchShared: String?
    /// "More oak than you usually drink." Nil without a map.
    public var matchApart: String?
    /// The grape, the region and why it suits the map, behind the expand button by the match. Empty without the
    /// user's history.
    public var insights: [NoteInsightUIModel]
    public var grapes: [String]
    public var notes: [String]
    public var pairings: [String]
    public var profile: PalateMap
    public var palate: PalateMap?
    public var findURL: URL?

    public init(wine: Wine, palate: PalateMap?, history: TasteHistory? = nil,
                resources: NotePaperResources = NotePaperResources()) {
        title = wine.name
        producer = wine.producer
        origin = wine.origin
        certificate = WineCertificateUIModel(wine: wine)
        facts = [
            NoteFactUIModel(label: resources.styleText, value: resources.type(wine.type)),
            NoteFactUIModel(label: resources.vintageText, value: wine.vintage.map(String.init) ?? resources.nonVintageText)
        ]
        if let oak = resources.oak(wine) { facts.append(NoteFactUIModel(label: resources.oakText, value: oak)) }
        let temperature = wine.serving.map { "\($0.lowerBound)–\($0.upperBound) °C" }
        serving = [temperature, wine.howToServe.map(WineCatalogText.editorial)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
        let fit = palate.map { PalateMatchUIModel(wine: wine.profile, palate: $0) }
        match = fit?.percent
        matchShared = fit?.shared
        matchApart = fit?.apart
        insights = history.map { NoteInsightUIModel.lines(wine: wine, palate: palate, history: $0, resources: resources) }
            ?? []
        grapes = NewNoteChipField.grapes.values(in: wine)
        notes = NewNoteChipField.notes.values(in: wine)
        pairings = NewNoteChipField.pairings.values(in: wine)
        profile = wine.profile
        self.palate = palate
        findURL = WineSearch.url(for: wine)
    }

    public func chips(_ field: NewNoteChipField) -> [String] {
        switch field {
        case .grapes: grapes
        case .notes: notes
        case .pairings: pairings
        }
    }
}

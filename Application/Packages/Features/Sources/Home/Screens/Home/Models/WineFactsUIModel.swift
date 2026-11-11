import Core
import Foundation

struct WineFactsUIModel {
    let wine: Wine
    let now: Date
    let resources: HomeResourcesUIModel
    struct Fact: Identifiable {
        var label: String
        var value: String
        var insight: String?
        var id: String { label }
    }

    var originFacts: [Fact] {
        var facts: [Fact] = []
        if !wine.originLine.isEmpty {
            // A wine known only by its country shows the country alone: a line on a whole country says little.
            let hasRegion = !(wine.region ?? "").isEmpty
            facts.append(Fact(label: resources.wineFactsOriginTitle, value: wine.originLine, insight: hasRegion ? wine.originInsight : nil))
        }
        // A plain origin label (a regional DOC, an IGT) says nothing the origin does not; only a notable one shows.
        if wine.hasNotableAppellation, !wine.classification.isEmpty {
            facts.append(Fact(label: resources.wineFactsAppellationTitle, value: wine.classification, insight: wine.appellationInsight))
        }
        return facts
    }

    var grapes: Fact? {
        guard !wine.grapes.isEmpty else { return nil }
        return Fact(label: resources.wineFactsGrapesTitle, value: wine.grapes.joined(separator: ", "))
    }

    var notes: Fact? {
        guard let note = wine.note, !note.isEmpty else { return nil }
        return Fact(label: resources.wineFactsNotesTitle, value: note)
    }

    var serving: Fact? {
        guard let serving = wine.serving else { return nil }
        return Fact(label: resources.wineFactsServingTitle, value: "\(serving.lowerBound)–\(serving.upperBound) °C",
                    insight: wine.howToServe)
    }

    /// "2023 · 3 years"
    func vintageLine(_ vintage: Int) -> String {
        let age = Calendar.current.component(.year, from: now) - vintage
        // The year as text: as a number it would be grouped by the locale, "2 023".
        let year = String(vintage)
        switch age {
        case ..<1: return year
        case 1: return String(localized: "\(year) · 1 year", bundle: .module)
        default: return String(localized: "\(year) · \(age) years", bundle: .module)
        }
    }

}

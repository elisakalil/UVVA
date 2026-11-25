import Core
import Foundation

/// Which wine each line of a list is (WINELIST-R05): its words read as a label's, looked up in the catalog on the
/// phone, and otherwise made from what the line says (the grape, the region, the section's type), with the map of
/// the catalog wines most like it. A line that says nothing of the wine is left out: it cannot be scored.
public enum WineListIdentifier {
    public static func wine(for entry: WineListEntry, index: LabelCatalogIndex, vocabulary: LabelVocabulary,
                            wines: [Wine], currentYear: Int) -> WineListWine? {
        let lines = [LabelLine(entry.name, height: 0.08)] + entry.details.map { LabelLine($0, height: 0.04) }
        var facts = LabelParser.parse(LabelText(lines), vocabulary: vocabulary, currentYear: currentYear)
        facts.type = entry.sectionType ?? facts.type
        if let match = LabelMatch.best(for: facts, in: index), match.isConfident {
            return WineListWine(entry: entry, wine: vocabulary.cleaning(match.wine), isKnown: true)
        }
        guard facts.type != nil || !facts.grapes.isEmpty || facts.region != nil,
              let profile = ProfileEstimate.estimate(grapes: facts.grapes, type: facts.type, region: facts.region,
                                                     in: wines) else { return nil }
        if !facts.hasName { facts.name = entry.name }
        var wine = ScannedWine.make(facts, profile: profile)
        if wine.name.isEmpty { wine.name = entry.name }
        return WineListWine(entry: entry, wine: wine, isKnown: false)
    }
}

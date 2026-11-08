import Core
import Foundation

/// A wine read on a label that the catalog does not have (CELLAR-R17, R23): its facts as read, and the map
/// estimated from the wines most like it.
public enum ScannedWine {
    public static func make(_ facts: LabelFacts, profile: PalateMap) -> Wine {
        let name = (facts.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let producer = (facts.producer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let place = facts.appellation ?? facts.region
        let origin = [place, facts.country].compactMap { $0 }.joined(separator: ", ")
        // As the catalog writes it, whatever the phone's language: "13.5% abv".
        let strength = facts.alcohol.map { "\($0.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "en_US_POSIX"))))% abv" }
        return Wine(id: WineKey.make(producer: producer, name: name, vintage: facts.vintage), name: name,
                    producer: producer, vintage: facts.vintage, type: facts.type ?? "", origin: origin,
                    region: facts.region, country: facts.country, grapes: facts.grapes, alcohol: facts.alcohol,
                    classification: [facts.appellation, strength].compactMap { $0 }.joined(separator: " · "),
                    profile: profile)
    }
}

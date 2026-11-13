import Foundation

public extension LabelFacts {
    /// These facts, with the gaps filled from `other`: the model's reading first, the parser's behind it.
    func filling(from other: LabelFacts) -> LabelFacts {
        LabelFacts(name: name ?? other.name, producer: producer ?? other.producer, vintage: vintage ?? other.vintage,
                   type: type ?? other.type, appellation: appellation ?? other.appellation,
                   region: region ?? other.region, country: country ?? other.country,
                   grapes: grapes.isEmpty ? other.grapes : grapes, alcohol: alcohol ?? other.alcohol,
                   titleLines: (titleLines + other.titleLines).reduce(into: []) { lines, line in
                       if !lines.contains(line) { lines.append(line) }
                   },
                   notes: notes.isEmpty ? other.notes : notes,
                   pairings: pairings.isEmpty ? other.pairings : pairings,
                   serving: serving ?? other.serving)
    }
}

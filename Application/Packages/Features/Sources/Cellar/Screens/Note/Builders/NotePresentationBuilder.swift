import CoreUI
import Core
import Foundation

/// What a saved note shows (CELLAR-R26). Pure: the entry, the catalog wine and the draft in, the UI model out.
struct NotePresentationBuilder {
    var entry: CellarEntry
    var wine: Wine?
    var resources = NoteResourcesUIModel()
    var dateStyle = Date.FormatStyle().day().month(.abbreviated)

    var date: String { entry.createdAt.formatted(dateStyle) }

    /// The appellation, then the vintage: "Chianti Classico · 2010".
    var subtitle: String {
        let appellation = entry.origin.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) }
        return [appellation ?? entry.region, entry.vintage.map(String.init)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var again: String { resources.verdict(CellarTag(entry)) }

    var coverTag: String? { entry.verdict == nil ? nil : again }

    /// A fact the entry doesn't have is left out (CELLAR-R26).
    var facts: [NoteFactUIModel] {
        let grapes = entry.grapes.joined(separator: " & ")
        let alcohol = entry.alcohol.map { $0.formatted(.number.precision(.fractionLength(0...1))) + "%" }
        return [(resources.grapeText, grapes), (resources.regionText, entry.region ?? ""),
                (resources.vintageText, entry.vintage.map(String.init) ?? ""), (resources.typeText, entry.type),
                (resources.alcoholText, alcohol ?? ""), (resources.producerText, entry.producer)]
            .filter { !$0.1.isEmpty }
            .map { NoteFactUIModel(label: $0.0, value: $0.1) }
    }

    var structure: [NoteStructureUIModel] {
        guard let profile = entry.wineProfile ?? wine?.profile else { return [] }
        return NoteStructureRow.allCases.map { row in
            let value = profile[row.axis]
            let filled = Int((value / PalateMap.range.upperBound * Double(NoteStructureUIModel.dotCount)).rounded())
            return NoteStructureUIModel(label: resources.label(row),
                                        filled: min(max(filled, 0), NoteStructureUIModel.dotCount),
                                        word: resources.level(value, of: row))
        }
    }

    /// "Violet, rose, iris." becomes "Violet  ·  Rose  ·  Iris".
    var aromas: String? {
        guard let note = entry.wineNotes ?? wine?.note else { return nil }
        let words = note.split(separator: ",")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: "."))) }
            .filter { !$0.isEmpty }
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return words.isEmpty ? nil : words.joined(separator: "  ·  ")
    }

    /// The order of the artboard: Yes, No, Maybe.
    static func verdicts(selected: Verdict?, resources: NoteResourcesUIModel) -> [NoteVerdictUIModel] {
        [Verdict.yes, .no, .maybe].map { verdict in
            NoteVerdictUIModel(verdict: verdict, label: resources.verdict(CellarTag(verdict)),
                               isSelected: verdict == selected)
        }
    }
}

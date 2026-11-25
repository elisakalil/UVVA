import Core
import Foundation

/// What the last label reading saw at each step (CELLAR-R17): the lines Vision read on each side, what the parser
/// and the model on the phone made of them, and the catalog's answer. Shown at the foot of the note in debug
/// builds, to see why a label gave little.
@MainActor
final class LabelReadingLog {
    struct Entry: Equatable {
        var front: [String] = []
        var back: [String] = []
        /// How sure the reading is of each back line, 0...1, in the same order.
        var backConfidence: [Double] = []
        /// The video frames the back label was scanned in; nil for a photo alone.
        var backScanFrames: Int?
        /// The lines left out as saying nothing of the wine: allergens, nutrition, codes, repeats.
        var droppedLines = 0
        /// What the camera gave, frame by frame, to replay the reading in a test.
        var export: LabelScanExport?
        var parsed: LabelFacts?
        /// Nil when the model gave nothing; `modelFailure` says why.
        var structured: LabelFacts?
        var modelFailure: String?
        /// "iOS 26.1 · pt-PT · language supported".
        var modelContext: String?
        /// The catalog wine the label was taken for, if any.
        var match: String?
        /// The pairings of the wine before the model was asked: the catalog's and the label's.
        var pairingsFound: [String] = []
        /// What the model added to them; nil when it was not asked.
        var pairingSuggestion: PairingSuggestionResult?
        /// Nothing read said wine (CELLAR-R21a): the reading stopped after the parser.
        var notWine = false
    }

    private(set) var last: Entry?

    func record(_ entry: Entry) { last = entry }

    /// The entry as plain text, one part under another.
    static func text(_ entry: Entry) -> String {
        var parts: [String] = []
        parts.append("FRONT · \(entry.front.count) lines\n" + lines(entry.front))
        let scan = (entry.backScanFrames.map { " · scanned in \($0) frames" } ?? "")
            + (entry.droppedLines > 0 ? " · \(entry.droppedLines) left out" : "")
        let back = entry.back.enumerated().map { index, line in
            entry.backConfidence.indices.contains(index)
                ? String(format: "%.2f  ", entry.backConfidence[index]) + line : line
        }
        parts.append("BACK · \(entry.back.count) lines\(scan)\n" + lines(back))
        parts.append("PARSER\n" + (entry.parsed.map(facts) ?? "—"))
        if entry.notWine {
            parts.append("NOT A WINE\nNo grape, no word for wine, no “% vol”, too few other signs: neither the model nor the catalog was asked.")
            return parts.joined(separator: "\n\n")
        }
        let model = entry.structured.map(facts) ?? "No answer: \(entry.modelFailure ?? "no reason given.")"
        parts.append("ON-DEVICE MODEL\n" + [entry.modelContext, model].compactMap { $0 }.joined(separator: "\n"))
        parts.append("CATALOG\n" + (entry.match.map { "Taken for \($0)" } ?? "No confident match: the wine is made from what was read."))
        if entry.match != nil || !entry.pairingsFound.isEmpty || entry.pairingSuggestion != nil {
            parts.append("PAIRINGS\n" + pairings(found: entry.pairingsFound, suggestion: entry.pairingSuggestion))
        }
        return parts.joined(separator: "\n\n")
    }

    /// "Found: …", then what the model added or why it added nothing.
    private static func pairings(found: [String], suggestion: PairingSuggestionResult?) -> String {
        let model: String
        if let suggestion, !suggestion.pairings.isEmpty {
            model = "Added by the model: " + suggestion.pairings.joined(separator: ", ")
        } else if let suggestion {
            model = "Model added nothing: \(suggestion.failure ?? "no reason given.")"
        } else {
            model = "Model not asked: the wine has enough pairings."
        }
        return "Found: \(list(found) ?? "—")\n" + model
    }

    private static func lines(_ lines: [String]) -> String {
        lines.isEmpty ? "—" : lines.joined(separator: "\n")
    }

    private static func facts(_ facts: LabelFacts) -> String {
        let rows: [(String, String?)] = [
            ("name", facts.name), ("producer", facts.producer), ("vintage", facts.vintage.map(String.init)),
            ("type", facts.type), ("appellation", facts.appellation), ("region", facts.region),
            ("country", facts.country), ("grapes", list(facts.grapes)),
            ("alcohol", facts.alcohol.map { "\($0)%" }), ("notes", list(facts.notes)),
            ("pairings", list(facts.pairings)),
            ("serving", facts.serving.map { "\($0.lowerBound)–\($0.upperBound) °C" }),
            ("designation", facts.designation), ("awards", list(facts.awards.map(\.text))),
            ("oak", facts.oakAging?.rawValue), ("woods", list(facts.oakWoods))
        ]
        return rows.map { "\($0.0): \($0.1 ?? "—")" }.joined(separator: "\n")
    }

    private static func list(_ values: [String]) -> String? {
        values.isEmpty ? nil : values.joined(separator: ", ")
    }
}

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
        var parsed: LabelFacts?
        /// Nil when the model gave nothing; `modelFailure` says why.
        var structured: LabelFacts?
        var modelFailure: String?
        /// "iOS 26.1 · pt-PT · language supported".
        var modelContext: String?
        /// The catalog wine the label was taken for, if any.
        var match: String?
    }

    private(set) var last: Entry?

    func record(_ entry: Entry) { last = entry }

    /// The entry as plain text, one part under another.
    static func text(_ entry: Entry) -> String {
        var parts: [String] = []
        parts.append("FRONT · \(entry.front.count) lines\n" + lines(entry.front))
        parts.append("BACK · \(entry.back.count) lines\n" + lines(entry.back))
        parts.append("PARSER\n" + (entry.parsed.map(facts) ?? "—"))
        let model = entry.structured.map(facts) ?? "No answer: \(entry.modelFailure ?? "no reason given.")"
        parts.append("ON-DEVICE MODEL\n" + [entry.modelContext, model].compactMap { $0 }.joined(separator: "\n"))
        parts.append("CATALOG\n" + (entry.match.map { "Taken for \($0)" } ?? "No confident match: the wine is made from what was read."))
        return parts.joined(separator: "\n\n")
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
            ("serving", facts.serving.map { "\($0.lowerBound)–\($0.upperBound) °C" })
        ]
        return rows.map { "\($0.0): \($0.1 ?? "—")" }.joined(separator: "\n")
    }

    private static func list(_ values: [String]) -> String? {
        values.isEmpty ? nil : values.joined(separator: ", ")
    }
}

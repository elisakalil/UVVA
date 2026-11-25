import Core
import Foundation

public enum NewNoteChipField: String, Identifiable, Sendable {
    case grapes, notes, pairings

    public var id: String { rawValue }

    /// What a word typed for it must name (CELLAR-R18a).
    var wordKind: ChipWordKind {
        switch self {
        case .grapes: .grape
        case .notes: .aroma
        case .pairings: .pairing
        }
    }

    func options(in wines: [Wine]) -> [String] {
        Self.ranked(wines, values: values(in:))
    }

    /// The values the wines have, the most frequent first, each once whatever its case.
    static func ranked(_ wines: [Wine], values: (Wine) -> [String]) -> [String] {
        var counts: [String: Int] = [:]
        var labels: [String: String] = [:]
        for wine in wines {
            for value in values(wine) {
                let label = value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !label.isEmpty else { continue }
                let key = label.lowercased()
                counts[key, default: 0] += 1
                labels[key] = labels[key] ?? label
            }
        }
        return counts.keys.sorted { lhs, rhs in
            let left = counts[lhs, default: 0]
            let right = counts[rhs, default: 0]
            return left == right ? lhs.localizedStandardCompare(rhs) == .orderedAscending : left > right
        }.compactMap { labels[$0] }
    }

    func values(in wine: Wine) -> [String] {
        switch self {
        case .grapes: wine.grapes
        case .notes: wine.noteItems
        case .pairings: wine.pairings
        }
    }
}

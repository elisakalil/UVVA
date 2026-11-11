import Core
import Foundation

public enum NewNoteChipField: String, Identifiable, Sendable {
    case grapes, notes, pairings

    public var id: String { rawValue }

    func options(in wines: [Wine]) -> [String] {
        var counts: [String: Int] = [:]
        var labels: [String: String] = [:]
        for wine in wines {
            for value in values(in: wine) {
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
        case .notes: wine.note?.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
        }.filter { !$0.isEmpty } ?? []
        case .pairings: wine.pairings
        }
    }
}

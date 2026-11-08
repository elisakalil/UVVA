import Core
import Foundation

/// The catalog prepared once for label lookups: each wine's words, and which wines use each word, so a label is
/// compared only with the wines that share a word with it.
public struct LabelCatalogIndex: Sendable {
    let entries: [LabelCatalogEntry]
    let byToken: [String: [Int]]

    public init(wines: [Wine]) {
        let entries = wines.map(LabelCatalogEntry.init)
        var byToken: [String: [Int]] = [:]
        for (index, entry) in entries.enumerated() {
            for token in entry.name.union(entry.producer) { byToken[token, default: []].append(index) }
        }
        self.entries = entries
        self.byToken = byToken
    }

    public var wines: [Wine] { entries.map(\.wine) }

    /// The wines sharing at least one word with `tokens`, in catalog order.
    func candidates(sharing tokens: Set<String>) -> [LabelCatalogEntry] {
        Set(tokens.flatMap { byToken[$0] ?? [] }).sorted().map { entries[$0] }
    }
}

import Core
import Foundation

/// "Search your cellar" looks in the wine's name, grapes, region and producer, ignoring case and accents (CELLAR-R11).
enum CellarSearchText {
    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func matches(_ entry: CellarEntry, query: String) -> Bool {
        let needle = fold(query)
        guard !needle.isEmpty else { return false }
        let fields = [entry.name, entry.producer, entry.region ?? ""] + entry.grapes
        return fields.contains { fold($0).contains(needle) }
    }
}

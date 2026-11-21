import Core
import Foundation
import Match

/// How close a wine of the Cellar sits to the user's map, the same match as on its note.
enum CellarMatch {
    /// Nil before the Quiz, or for a wine saved without its profile.
    static func percent(_ entry: CellarEntry, palate: PalateMap?) -> Int? {
        guard let palate, let profile = entry.wineProfile else { return nil }
        return Similarity.percent(profile, palate)
    }

    /// The bands of the Match filter, closest first.
    enum Band: CaseIterable, Sendable {
        case ninety, eighty, seventy, sixty, below

        init(_ percent: Int) {
            switch percent {
            case 90...: self = .ninety
            case 80..<90: self = .eighty
            case 70..<80: self = .seventy
            case 60..<70: self = .sixty
            default: self = .below
            }
        }
    }
}

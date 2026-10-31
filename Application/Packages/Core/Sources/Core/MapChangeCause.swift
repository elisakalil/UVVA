import Foundation

/// What changed the palate map (ARCHITECTURE §2.1).
public enum MapChangeCause: Codable, Equatable, Sendable {
    case quiz
    case rating(wineKey: String, verdict: Verdict)
}

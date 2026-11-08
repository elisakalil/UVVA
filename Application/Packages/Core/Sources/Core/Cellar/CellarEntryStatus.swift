import Foundation

/// Tasted counts towards the map and has a verdict; Want to try waits for a first taste (CELLAR-R01).
public enum CellarEntryStatus: String, Codable, Sendable {
    case tasted, wantToTry
}

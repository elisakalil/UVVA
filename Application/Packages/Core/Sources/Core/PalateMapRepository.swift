import Foundation

/// Reads and writes the user's palate map (Personal store, ARCHITECTURE §2.1).
public protocol PalateMapRepository: Sendable {
    /// The current map, or nil before the first Quiz.
    func currentMap() async throws -> PalateMap?
    /// "Keep this map": a new map whose history starts with the Quiz (QUIZ-R18, R18a).
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws
}

import Foundation

/// Reads and writes the user's palate map (Personal store, ARCHITECTURE §2.1).
public protocol PalateMapRepository: Sendable {
    /// The current map, or nil before the first Quiz.
    func currentMap() async throws -> PalateMap?
    /// "Keep this map": a new map whose history starts with the Quiz (QUIZ-R18, R18a).
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws
    /// "Keep this map", with the answers it was drawn from, kept out of sight (QUIZ-R04a).
    func saveQuizMap(_ map: PalateMap, answers: [PalateAxis: Int], at date: Date) async throws
    /// Every change of the current map, oldest first; the first is the Quiz (YOU-R10).
    func history() async throws -> [MapChange]
    /// A rating moved the map (QUIZ-R22): the current map becomes `map`, and the change joins its history.
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws
}

public extension PalateMapRepository {
    /// A repository that keeps no answers keeps the map alone.
    func saveQuizMap(_ map: PalateMap, answers: [PalateAxis: Int], at date: Date) async throws {
        try await saveQuizMap(map, at: date)
    }
}

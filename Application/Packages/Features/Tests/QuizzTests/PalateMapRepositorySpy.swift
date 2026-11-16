import Core
import Foundation
import Synchronization

/// Records the maps saved; can be told to fail.
final class PalateMapRepositorySpy: PalateMapRepository {
    private let saved = Mutex<[PalateMap]>([])
    private let answers = Mutex<[[PalateAxis: Int]]>([])
    let fails: Bool

    init(fails: Bool = false) { self.fails = fails }

    var savedMaps: [PalateMap] { saved.withLock { $0 } }
    var savedAnswers: [[PalateAxis: Int]] { answers.withLock { $0 } }

    func currentMap() async throws -> PalateMap? { savedMaps.last }
    func history() async throws -> [MapChange] { [] }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {}

    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {
        if fails { throw CocoaError(.fileWriteUnknown) }
        saved.withLock { $0.append(map) }
    }

    func saveQuizMap(_ map: PalateMap, answers: [PalateAxis: Int], at date: Date) async throws {
        try await saveQuizMap(map, at: date)
        self.answers.withLock { $0.append(answers) }
    }
}

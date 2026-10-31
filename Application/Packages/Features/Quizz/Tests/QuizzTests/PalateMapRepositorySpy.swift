import Core
import Foundation
import Synchronization

/// Records the maps saved; can be told to fail.
final class PalateMapRepositorySpy: PalateMapRepository {
    private let saved = Mutex<[PalateMap]>([])
    let fails: Bool

    init(fails: Bool = false) { self.fails = fails }

    var savedMaps: [PalateMap] { saved.withLock { $0 } }

    func currentMap() async throws -> PalateMap? { savedMaps.last }
    func history() async throws -> [MapChange] { [] }

    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {
        if fails { throw CocoaError(.fileWriteUnknown) }
        saved.withLock { $0.append(map) }
    }
}

import Core
import Foundation
@testable import Cellar

struct CellarLoaderStub: LoadCellarUseCaseProtocol {
    var entries: [CellarEntry]
    func execute() async throws -> [CellarEntry] { entries }
}

@MainActor
final class PreferencesStub: CellarPreferencesProtocol {
    var viewMode: CellarViewMode = .grid
    var bannerViews = 0
}

enum Entries {
    static func entry(_ id: String, name: String? = nil, producer: String = "", type: String = "Red",
                      region: String? = nil, country: String? = nil, grapes: [String] = [],
                      verdict: Verdict? = nil, at seconds: TimeInterval = 0) -> CellarEntry {
        CellarEntry(id: id, name: name ?? id, producer: producer, type: type, region: region, country: country,
                    grapes: grapes, status: verdict == nil ? .wantToTry : .tasted, verdict: verdict,
                    createdAt: Date(timeIntervalSince1970: seconds))
    }
}

@MainActor
struct NoteLoaderStub: LoadNoteUseCaseProtocol {
    var wine: Wine?
    func execute(_ wineKey: String) async -> Wine? { wine }
}

@MainActor
final class SaveNoteSpy: SaveNoteUseCaseProtocol {
    var saved: [(String, Verdict?, String)] = []
    var error: Error?
    func execute(_ entry: CellarEntry, verdict: Verdict?, note: String) async throws {
        if let error { throw error }
        saved.append((entry.id, verdict, note))
    }
}

@MainActor
final class DeleteNoteSpy: DeleteNoteUseCaseProtocol {
    var deleted: [String] = []
    func execute(_ entry: CellarEntry) async throws { deleted.append(entry.id) }
}

@MainActor
final class RecalculateSpy: RecalculateMapUseCaseProtocol {
    var calls: [(String, Verdict?)] = []
    func execute(changing wineKey: String, to verdict: Verdict?) async throws { calls.append((wineKey, verdict)) }
}

actor CellarSpy: CellarRepository {
    private(set) var updates: [(String, Verdict?, String?)] = []
    private(set) var deletes: [String] = []
    func entries() async throws -> [CellarEntry] { [] }
    func wineKeys() async throws -> Set<String> { [] }
    func addWantToTry(_ wine: Wine) async throws {}
    func tastedWineKeys() async throws -> Set<String> { [] }
    func addTasted(_ wine: Wine, verdict: Verdict) async throws {}
    func update(_ wineKey: String, verdict: Verdict?, note: String?) async throws { updates.append((wineKey, verdict, note)) }
    func delete(_ wineKey: String) async throws { deletes.append(wineKey) }
}

actor MapsSpy: PalateMapRepository, PalateHistoryRewriting {
    var map: PalateMap?
    var changes: [MapChange]
    private(set) var rated: [(String, Verdict)] = []
    private(set) var rewritten: [[MapChange]] = []

    init(map: PalateMap? = nil, history: [MapChange] = []) {
        self.map = map
        self.changes = history
    }

    func currentMap() async throws -> PalateMap? { map }
    func saveQuizMap(_ map: PalateMap, at date: Date) async throws {}
    func history() async throws -> [MapChange] { changes }
    func saveRatedMap(_ map: PalateMap, wineKey: String, verdict: Verdict, at date: Date) async throws {
        self.map = map
        rated.append((wineKey, verdict))
    }
    func rewriteHistory(_ history: [MapChange]) async throws {
        changes = history
        rewritten.append(history)
    }
}

struct WinesStub: WineLookup {
    var wines: [String: Wine]
    func wines(keys: Set<String>) async throws -> [String: Wine] { wines.filter { keys.contains($0.key) } }
}

enum Maps {
    static func flat(_ value: Double) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
    }

    static func wine(_ id: String, _ value: Double) -> Wine {
        Wine(id: id, name: id, origin: "", profile: flat(value))
    }
}

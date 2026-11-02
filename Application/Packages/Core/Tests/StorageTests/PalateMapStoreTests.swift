import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct PalateMapStoreTests {
    let container: ModelContainer
    let store: PalateMapStore

    init() throws {
        container = try AppStore.makeInMemoryContainer()
        store = PalateMapStore(modelContainer: container)
    }

    private func map(_ value: Double) -> PalateMap {
        PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { ($0, value) }))
    }

    @Test func beforeTheQuiz_thereIsNoMap() async throws {
        #expect(try await store.currentMap() == nil)
    }

    // MARK: QUIZ-R18 · Keep this map

    @Test func QUIZ_R18_keep_savesTheMap_withTheQuizAsFirstHistoryEntry() async throws {
        let date = Date(timeIntervalSince1970: 1_000)
        try await store.saveQuizMap(map(4), at: date)
        #expect(try await store.currentMap() == map(4))
        let entity = try #require(try ModelContext(container).fetch(FetchDescriptor<PalateMapEntity>()).first)
        #expect(entity.createdAt == date)
        #expect(entity.history == [MapChange(date: date, cause: .quiz, values: map(4).values)])
    }

    // MARK: QUIZ-R18a · Refazer

    @Test func QUIZ_R18a_redo_replacesTheMap_andRestartsTheHistory() async throws {
        try await store.saveQuizMap(map(6.4), at: Date(timeIntervalSince1970: 1_000))
        try await store.saveQuizMap(map(3), at: Date(timeIntervalSince1970: 2_000))
        let all = try ModelContext(container).fetch(FetchDescriptor<PalateMapEntity>())
        #expect(all.count == 1)
        #expect(all.first?.map == map(3))
        #expect(all.first?.history.count == 1)
    }
}

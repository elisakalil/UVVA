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

    // MARK: QUIZ-R22 · A rating moves the map

    @Test func QUIZ_R22_rating_movesTheMap_andJoinsTheHistory() async throws {
        try await store.saveQuizMap(map(5), at: Date(timeIntervalSince1970: 1_000))
        try await store.saveRatedMap(map(6), wineKey: "w", verdict: .yes, at: Date(timeIntervalSince1970: 2_000))
        #expect(try await store.currentMap() == map(6))
        let history = try await store.history()
        #expect(history.map(\.cause) == [.quiz, .rating(wineKey: "w", verdict: .yes)])
        #expect(history.last?.values == map(6).values)
    }

    @Test func rating_beforeTheQuiz_throws() async {
        await #expect(throws: PalateMapStoreError.self) {
            try await store.saveRatedMap(map(6), wineKey: "w", verdict: .yes, at: .now)
        }
    }

    // MARK: CELLAR-R29 · Recalcular o mapa

    @Test func CELLAR_R29_rewrite_replacesTheHistory_andTheMap() async throws {
        try await store.saveQuizMap(map(4), at: Date(timeIntervalSince1970: 0))
        try await store.saveRatedMap(map(6), wineKey: "a", verdict: .yes, at: Date(timeIntervalSince1970: 1))
        let quizOnly = Array(try await store.history().prefix(1))
        try await store.rewriteHistory(quizOnly)
        #expect(try await store.history() == quizOnly)
        #expect(try await store.currentMap() == map(4))
    }
}

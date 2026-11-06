import Core
import Foundation
import SwiftData
import Testing
@testable import Storage

struct LearningStoreTests {
    let container: ModelContainer
    let store: LearningStore
    let day = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try AppStore.makeInMemoryContainer()
        store = LearningStore(modelContainer: container)
    }

    // MARK: LEARN-R14 · Sair e retomar

    @Test func LEARN_R14_savedStepAndAnswers_comeBack() async throws {
        let progress = LessonProgress(lessonID: "path-01-l03", courseID: "path-01", currentStep: 4,
                                      answers: [2: .options([1]), 4: .order([2, 0, 1])], lastOpenedAt: day)
        try await store.save(progress)
        #expect(try await store.progress()["path-01-l03"] == progress)
    }

    @Test func save_twice_keepsOneRecordWithTheLastValues() async throws {
        var progress = LessonProgress(lessonID: "path-01-l01", courseID: "path-01", lastOpenedAt: day)
        try await store.save(progress)
        progress.currentStep = 5
        progress.completedAt = day
        progress.xp = 15
        try await store.save(progress)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<LessonProgressEntity>()) == 1)
        #expect(try await store.progress()["path-01-l01"]?.isCompleted == true)
    }

    @Test func delayedOlderRevision_doesNotOverwriteNewerProgress() async throws {
        let newer = LessonProgress(lessonID: "path-01-l01", courseID: "path-01", currentStep: 4,
                                   answers: [2: .options([1])], lastOpenedAt: day, revision: 2)
        try await store.save(newer)
        let older = LessonProgress(lessonID: newer.lessonID, courseID: newer.courseID, currentStep: 0,
                                   lastOpenedAt: day.addingTimeInterval(1), revision: 1)
        try await store.save(older)
        let reopenedStore = LearningStore(modelContainer: container)
        #expect(try await reopenedStore.progress()[newer.lessonID] == newer)
    }

    @Test func completedLesson_isNotReopenedByDelayedSave() async throws {
        let completed = LessonProgress(lessonID: "path-01-l01", courseID: "path-01", currentStep: 5,
                                       completedAt: day, lastOpenedAt: day, xp: 15, revision: 2)
        try await store.save(completed)
        try await store.save(LessonProgress(lessonID: completed.lessonID, courseID: completed.courseID,
                                            lastOpenedAt: day.addingTimeInterval(1), revision: 3))
        #expect(try await store.progress()[completed.lessonID] == completed)
    }

    @Test @MainActor func concurrentWrites_useBackgroundQueue_andKeepNewestRevision() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for revision in 1...30 {
                group.addTask {
                    try await store.save(LessonProgress(lessonID: "path-01-l01", courseID: "path-01",
                        currentStep: revision % 5, lastOpenedAt: day, revision: revision))
                }
            }
            try await group.waitForAll()
        }
        let reloaded = try await LearningStore(modelContainer: container).progress()["path-01-l01"]
        #expect(reloaded?.revision == 30)
        #expect(reloaded?.currentStep == 0)
    }

    // MARK: LEARN-R22 · Um certificado por curso

    @Test func LEARN_R22_aSecondCertificateForTheSameCourse_isNotAdded() async throws {
        try await store.addCertificate(Certificate(courseID: "grape-tannat", date: day))
        try await store.addCertificate(Certificate(courseID: "grape-tannat", date: day.addingTimeInterval(86_400)))
        #expect(try await store.certificates() == [Certificate(courseID: "grape-tannat", date: day)])
    }

    @Test func deleteAccount_removesProgressAndCertificates() async throws {
        try await store.save(LessonProgress(lessonID: "path-01-l01", courseID: "path-01", lastOpenedAt: day))
        try await store.addCertificate(Certificate(courseID: "path-01", date: day))
        try await ProfileStore(modelContainer: container).deleteAccount()
        #expect(try await store.progress().isEmpty)
        #expect(try await store.certificates().isEmpty)
    }
    private var region: Course {
        Course(id: "region-test", kind: .region, order: 1, title: "Region", about: "", lessons: (1...6).map {
            LessonSummary(id: "region-test-l0\($0)", courseID: "region-test", order: $0,
                title: "Lesson \($0)", subtitle: "", xp: 15, minutes: 3, isReview: false, objectives: [])
        })
    }

    private func record(_ number: Int, completed: Bool, revision: Int = 1) -> LessonProgress {
        LessonProgress(lessonID: region.lessons[number - 1].id, courseID: region.id, currentStep: completed ? 5 : 2,
            completedAt: completed ? day : nil, lastOpenedAt: day, xp: completed ? 15 : 0, revision: revision)
    }

    @Test func moduleState_startsAtZero_andPartialLessonDoesNotIncrement() async throws {
        #expect(try await store.snapshot(for: [region]).modules[region.id]?.state == 0)
        try await store.save(record(1, completed: false), in: region)
        #expect(try await store.snapshot(for: [region]).modules[region.id]?.state == 0)
    }

    @Test func completeTwoLessons_partialThird_reloadKeepsStateTwo() async throws {
        try await store.save(record(1, completed: true), in: region)
        #expect(try await store.snapshot(for: [region]).modules[region.id]?.state == 1)
        try await store.save(record(2, completed: true), in: region)
        try await store.save(record(3, completed: false), in: region)
        let snapshot = try await LearningStore(modelContainer: container).snapshot(for: [region])
        #expect(snapshot.modules[region.id]?.state == 2)
        #expect(snapshot.lessons[region.lessons[2].id]?.currentStep == 2)
        #expect(CourseRules.entry(for: region, module: snapshot.modules[region.id], progress: snapshot.lessons)?.lessonID == region.lessons[2].id)
    }

    @Test func duplicateConcurrentCompletion_incrementsStateOnlyOnce() async throws {
        let record = record(1, completed: true)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<20 { group.addTask { try await store.save(record, in: region) } }
            try await group.waitForAll()
        }
        #expect(try await store.snapshot(for: [region]).modules[region.id]?.state == 1)
    }

    @Test func outOfOrderCompletion_rollsBackLessonAndModuleTogether() async throws {
        do {
            try await store.save(record(3, completed: true), in: region)
            Issue.record("An unfinished module cannot complete lesson 3 before 1 and 2")
        } catch LearningStore.StateError.outOfOrderCompletion { }
        let snapshot = try await store.snapshot(for: [region])
        #expect(snapshot.modules[region.id]?.state == 0)
        #expect(snapshot.lessons[region.lessons[2].id] == nil)
    }

    @Test func legacyMigration_isPersistedOnce_andLaterLessonRecordsCannotOverrideState() async throws {
        try await store.save(record(1, completed: true))
        try await store.save(record(2, completed: true))
        #expect(try await store.snapshot(for: [region]).modules[region.id]?.state == 2)
        try await store.save(record(3, completed: true)) // Simulates an old client writing only lesson records.
        #expect(try await LearningStore(modelContainer: container).snapshot(for: [region]).modules[region.id]?.state == 2)
    }

    @Test func lastCompletion_setsFinalState_withoutInventingASeventhLesson() async throws {
        for number in 1...6 { try await store.save(record(number, completed: true), in: region) }
        let snapshot = try await store.snapshot(for: [region])
        #expect(snapshot.modules[region.id]?.state == 6)
        #expect(snapshot.modules[region.id]?.completedAt == day)
        #expect(CourseRules.entry(for: region, module: snapshot.modules[region.id], progress: snapshot.lessons) == nil)
    }

    @Test func deletingAccount_alsoDeletesPersistedModuleState() async throws {
        try await store.save(record(1, completed: true), in: region)
        try await ProfileStore(modelContainer: container).deleteAccount()
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ModuleProgressEntity>()) == 0)
    }

}

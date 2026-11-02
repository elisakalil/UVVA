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
}

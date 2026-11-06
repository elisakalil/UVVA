import Combine
import Core
import Foundation
import Synchronization
import Testing
@testable import Learn

/// Deliberately pauses I/O without actors, timers, or scheduling assumptions.
private final class ControlledLearning: LearningRepository {
    func snapshot(for courses: [Course]) async throws -> LearningSnapshot { testSnapshot(courses, lessons: try await progress()) }
    func save(_ progress: LessonProgress, in course: Course) async throws { try await save(progress) }

    struct State: Sendable {
        var progress: [String: LessonProgress] = [:]
        var saveCount = 0
        var suspendRead = false
        var suspendSave = false
        var failRead = false
        var failSave = false
        var usedMainThread = false
        var reading: CheckedContinuation<Void, Never>?
        var saving: CheckedContinuation<Void, Never>?
    }
    let state = Mutex(State())

    func progress() async throws -> [String: LessonProgress] {
        await withCheckedContinuation { continuation in
            state.withLock {
                $0.usedMainThread = $0.usedMainThread || Thread.isMainThread
                if $0.suspendRead { $0.reading = continuation } else { continuation.resume() }
            }
        }
        return try state.withLock {
            if $0.failRead { throw URLError(.cannotLoadFromNetwork) }
            return $0.progress
        }
    }

    func save(_ progress: LessonProgress) async throws {
        await withCheckedContinuation { continuation in
            state.withLock {
                $0.saveCount += 1
                $0.usedMainThread = $0.usedMainThread || Thread.isMainThread
                if $0.suspendSave { $0.saving = continuation } else { continuation.resume() }
            }
        }
        try state.withLock {
            if $0.failSave { throw URLError(.cannotWriteToFile) }
            $0.progress[progress.lessonID] = progress
        }
    }

    func resumeSave() {
        let continuation = state.withLock { state in
            state.suspendSave = false
            defer { state.saving = nil }
            return state.saving
        }
        continuation?.resume()
    }

    func resumeRead() {
        let continuation = state.withLock { state in
            state.suspendRead = false
            defer { state.reading = nil }
            return state.reading
        }
        continuation?.resume()
    }

    func certificates() async throws -> [Certificate] { [] }
    func addCertificate(_ certificate: Certificate) async throws {}
}

@MainActor
struct LearnNavigationRaceTests {
    private func model(_ learning: ControlledLearning, course: Course) -> LearnViewModel {
        LearnFactory(catalog: CatalogStub(all: [course], lessons: Fixture.lessons(of: course)),
                     learning: learning, profiles: ProfilesStub(), now: { Fixture.day }, pickToast: { _ in 0 })
            .makeViewModel()
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(5))
        }
        try #require(condition())
    }

    @Test func open_showsLoadingUntilFreshReadCompletes_withoutMainThreadIO() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        await model.load()
        let id = course.lessons[0].id
        learning.state.withLock {
            $0.progress[id] = LessonProgress(lessonID: id, courseID: course.id, currentStep: 3, lastOpenedAt: Fixture.day)
            $0.suspendRead = true
        }
        let opening = Task { await model.openCourse(id: course.id, lessonID: id) }
        try await waitUntil { learning.state.withLock { $0.reading != nil } }
        #expect(model.uiModel.isLoadingLesson)
        #expect(model.uiModel.isPresentingPlayer)
        #expect(model.player == nil)
        learning.resumeRead()
        await opening.value
        #expect(!model.uiModel.isLoadingLesson)
        #expect(model.player?.stepIndex == 3)
        #expect(!learning.state.withLock { $0.usedMainThread })
    }

    @Test func exit_savesExactlyOnce_andReopenWaitsForSave_thenAlwaysResumesExactCursor() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        let id = course.lessons[0].id
        await model.openCourse(id: course.id, lessonID: id)
        let original = try #require(model.player)
        original.begin()
        original.primary()
        original.primary()
        original.back()
        #expect(original.stepIndex == 1)
        #expect(learning.state.withLock { $0.saveCount } == 0)
        learning.state.withLock { $0.suspendSave = true }
        original.close()
        original.close() // Duplicate dismissal cannot enqueue another save.
        try await waitUntil { learning.state.withLock { $0.saving != nil } }
        let opening = Task { await model.openCourse(id: course.id, lessonID: id) }
        await Task.yield()
        #expect(model.uiModel.isLoadingLesson)
        #expect(model.player === original)
        #expect(learning.state.withLock { $0.saveCount } == 1)
        learning.resumeSave()
        await opening.value
        #expect(model.player?.stepIndex == 1)
        for _ in 0..<3 {
            model.player?.close()
            await model.openCourse(id: course.id, lessonID: id)
            #expect(model.player?.stepIndex == 1)
        }
        #expect(!learning.state.withLock { $0.usedMainThread })
    }

    @Test func readFailure_doesNotOpenFromCache_andRetryLoadsSavedState() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        await model.load()
        learning.state.withLock { $0.failRead = true }
        await model.openCourse(id: course.id, lessonID: course.lessons[0].id)
        #expect(model.player == nil)
        #expect(model.uiModel.lessonError != nil)
        #expect(!model.uiModel.isLoadingLesson)
        learning.state.withLock { $0.failRead = false }
        await model.retryLesson()
        #expect(model.player != nil)
        #expect(model.uiModel.lessonError == nil)
    }

    @Test func saveFailure_keepsPlayerUntilRetryPersistsItsExactState() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        let id = course.lessons[0].id
        await model.openCourse(id: course.id, lessonID: id)
        let player = try #require(model.player)
        player.begin()
        player.primary()
        learning.state.withLock { $0.failSave = true }
        player.close()
        try await waitUntil { model.uiModel.lessonError != nil }
        #expect(model.player === player)
        #expect(learning.state.withLock { $0.progress[id] } == nil)
        learning.state.withLock { $0.failSave = false }
        await model.retryLesson()
        try await waitUntil { model.player == nil }
        #expect(learning.state.withLock { $0.progress[id]?.currentStep } == 1)
        await model.openCourse(id: course.id, lessonID: id)
        #expect(model.player?.stepIndex == 1)
    }
    @Test func leavingOnCover_resumesCoverRatherThanStepZero() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        let id = course.lessons[0].id
        await model.openCourse(id: course.id, lessonID: id)
        let player = try #require(model.player)
        player.begin()
        player.primary()
        player.back()
        player.back()
        #expect(player.playerState == .cover)
        player.close()
        await model.openCourse(id: course.id, lessonID: id)
        #expect(model.player?.playerState == .cover)
        #expect(learning.state.withLock { $0.progress[id]?.currentStep } == -1)
    }

    @Test func completedLesson_resumesItsSavedScreen_withoutResettingOrAwardingAgain() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let id = course.lessons[0].id
        learning.state.withLock {
            $0.progress[id] = LessonProgress(lessonID: id, courseID: course.id, currentStep: 3,
                completedAt: Fixture.day, lastOpenedAt: Fixture.day, xp: 15)
        }
        let model = model(learning, course: course)
        await model.openCourse(id: course.id, lessonID: id)
        #expect(model.player?.stepIndex == 3)
        #expect(model.player?.isReview == true)
        model.player?.close()
        await model.openCourse(id: course.id, lessonID: id)
        #expect(model.player?.stepIndex == 3)
        #expect(learning.state.withLock { $0.progress[id]?.xp } == 15)
    }

    @Test func delayedOlderOpening_cannotReplaceLatestSelection() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        await model.load()
        learning.state.withLock { $0.suspendRead = true }
        let old = Task { await model.openCourse(id: course.id, lessonID: course.lessons[0].id) }
        try await waitUntil { learning.state.withLock { $0.reading != nil } }
        learning.state.withLock { $0.suspendRead = false }
        await model.openCourse(id: course.id, lessonID: course.lessons[1].id)
        let latest = try #require(model.player)
        learning.resumeRead()
        await old.value
        #expect(model.player === latest)
        #expect(model.player?.lesson.id == course.lessons[0].id) // state 0 cannot skip lesson 1.
    }

    @Test func backgroundDeparture_usesSameSaveBarrier_withoutDismissingLesson() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        let id = course.lessons[0].id
        await model.openCourse(id: course.id, lessonID: id)
        let player = try #require(model.player)
        player.begin()
        player.primary()
        await model.saveLessonOnBackground()
        try await waitUntil { !model.uiModel.isLoadingLesson }
        #expect(model.player === player)
        #expect(learning.state.withLock { $0.progress[id]?.currentStep } == 1)
        player.primary()
        player.close()
        try await waitUntil { model.player == nil }
        #expect(learning.state.withLock { $0.progress[id]?.currentStep } == 2)
        #expect(learning.state.withLock { $0.saveCount } == 2)
    }

    @Test func leavingSavedSummary_doesNotSaveAgainOrShowAnotherLoadingCycle() async throws {
        let course = Fixture.course("grape-tannat")
        let learning = ControlledLearning()
        let model = model(learning, course: course)
        await model.openCourse(id: course.id)
        let player = try #require(model.player)
        player.begin()
        player.primary()
        player.primary()
        player.tapOption(2)
        player.primary()
        player.primary()
        player.primary()
        player.tapOption(0)
        player.primary()
        player.primary() // Completing the lesson saves before the Summary.
        try await waitUntil { !model.uiModel.isLoadingLesson }
        #expect(player.isSummary)
        #expect(player.hasSavedSummary)
        #expect(learning.state.withLock { $0.saveCount } == 1)
        var loadingEvents: [Bool] = []
        let subscription = model.lessonLoadingPublisher.sink { loadingEvents.append($0) }
        defer { subscription.cancel() }
        player.primary() // Next lesson: use the completion that was already saved.
        player.primary() // Repeated taps cannot restart saving either.
        try await waitUntil { model.player?.lesson.id == course.lessons[1].id }
        #expect(learning.state.withLock { $0.saveCount } == 1)
        #expect(!loadingEvents.contains(true))
    }

    @Test func finishModuleAndCloseCertificate_doNotRepeatSummarySaveOrLoading() async throws {
        let course = Fixture.course("grape-tannat", lessons: 1)
        let summary = course.lessons[0]
        let learning = ControlledLearning()
        let catalog = CatalogStub(all: [course], lessons: [summary.id: Lesson(summary: summary,
            steps: [.concept(title: "One", body: "Body", highlight: nil), .summary(title: "Done", points: [])])])
        let model = LearnFactory(catalog: catalog, learning: learning, profiles: ProfilesStub()).makeViewModel()
        await model.openCourse(id: course.id)
        let player = try #require(model.player)
        player.begin()
        player.primary()
        try await waitUntil { !model.uiModel.isLoadingLesson }
        #expect(learning.state.withLock { $0.saveCount } == 1)
        var loadingEvents: [Bool] = []
        let subscription = model.lessonLoadingPublisher.sink { loadingEvents.append($0) }
        defer { subscription.cancel() }
        player.primary()
        #expect(player.certificate != nil)
        player.closeCertificate()
        try await waitUntil { model.player == nil }
        #expect(learning.state.withLock { $0.saveCount } == 1)
        #expect(!loadingEvents.contains(true))
    }

}

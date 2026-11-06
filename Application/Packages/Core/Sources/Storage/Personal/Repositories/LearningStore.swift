import Core
import Foundation
import SwiftData

/// `LearningRepository` on the Personal store. Two devices may each write a lesson before syncing, so reads keep
/// the latest record of a lesson: completed first, then revision and last-opened time.
public final class LearningStore: LearningRepository, @unchecked Sendable {
    // Only this serial queue may create or access the SwiftData context.
    private let queue = DispatchQueue(label: "app.uvva.lesson-progress", qos: .utility)
    private let container: ModelContainer
    private lazy var modelContext: ModelContext = {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }()

    public init(modelContainer: ModelContainer) { container = modelContainer }

    private func perform<T: Sendable>(_ work: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                dispatchPrecondition(condition: .notOnQueue(.main))
                continuation.resume(with: Result { try work() })
            }
        }
    }

    public func snapshot(for courses: [Course]) async throws -> LearningSnapshot {
        try await perform {
            do {
                let lessons = try self.readProgress()
                var modules: [String: ModuleProgress] = [:]
                for course in courses {
                    let entity = try self.module(for: course, legacy: lessons)
                    modules[course.id] = ModuleProgress(courseID: course.id, state: entity.state,
                        lastOpenedAt: entity.lastOpenedAt, completedAt: entity.completedAt)
                }
                if self.modelContext.hasChanges { try self.modelContext.save() }
                return LearningSnapshot(lessons: lessons, modules: modules)
            } catch { self.modelContext.rollback(); throw error }
        }
    }

    public enum StateError: Error { case invalidLesson, outOfOrderCompletion }

    public func save(_ progress: LessonProgress, in course: Course) async throws {
        try await perform {
            do {
                guard progress.courseID == course.id,
                      let index = course.lessons.firstIndex(where: { $0.id == progress.lessonID }) else {
                    throw StateError.invalidLesson
                }
                let module = try self.module(for: course, legacy: self.readProgress())
                let accepted = try self.persist(progress, saving: false)
                if accepted {
                    if progress.isCompleted {
                        let number = index + 1
                        guard number <= module.state + 1 else { throw StateError.outOfOrderCompletion }
                        // Retries and reviews cannot increment twice or decrease the cursor.
                        if number == module.state + 1 { module.state = number }
                        if module.state == course.lessons.count, module.completedAt == nil {
                            module.completedAt = progress.completedAt
                        }
                    }
                    module.lastOpenedAt = max(module.lastOpenedAt ?? .distantPast, progress.lastOpenedAt)
                }
                // The lesson completion and module cursor become durable together.
                try self.modelContext.save()
            } catch { self.modelContext.rollback(); throw error }
        }
    }

    /// One-time migration only. Once this record exists, reads never derive state from lessons.
    private func module(for course: Course, legacy: [String: LessonProgress]) throws -> ModuleProgressEntity {
        let id = course.id
        let existing = try modelContext.fetch(FetchDescriptor<ModuleProgressEntity>(predicate: #Predicate { $0.courseId == id }))
        if let entity = existing.max(by: { $0.state < $1.state }) {
            for duplicate in existing where duplicate !== entity { modelContext.delete(duplicate) }
            return entity
        }
        let entity = ModuleProgressEntity(courseId: id)
        for lesson in course.lessons {
            guard legacy[lesson.id]?.isCompleted == true else { break }
            entity.state += 1
        }
        let opened = course.lessons.compactMap { legacy[$0.id] }
        entity.lastOpenedAt = opened.map(\.lastOpenedAt).max()
        if entity.state == course.lessons.count { entity.completedAt = opened.compactMap(\.completedAt).max() }
        modelContext.insert(entity)
        return entity
    }

    public func progress() async throws -> [String: LessonProgress] {
        try await perform { try self.readProgress() }
    }

    public func save(_ progress: LessonProgress) async throws {
        try await perform {
            do { _ = try self.persist(progress) }
            catch { self.modelContext.rollback(); throw error }
        }
    }

    public func certificates() async throws -> [Certificate] {
        try await perform { try self.readCertificates() }
    }

    public func addCertificate(_ certificate: Certificate) async throws {
        try await perform { try self.writeCertificate(certificate) }
    }

    private func readProgress() throws -> [String: LessonProgress] {
        var byLesson: [String: LessonProgress] = [:]
        for entity in try modelContext.fetch(FetchDescriptor<LessonProgressEntity>()) {
            let progress = try Self.progress(entity)
            if let kept = byLesson[progress.lessonID], Self.isFurther(kept, than: progress) { continue }
            byLesson[progress.lessonID] = progress
        }
        return byLesson
    }

    private func persist(_ progress: LessonProgress, saving: Bool = true) throws -> Bool {
        let lessonId = progress.lessonID
        let existing = try modelContext.fetch(FetchDescriptor<LessonProgressEntity>(predicate: #Predicate { $0.lessonId == lessonId }))
        let candidates = try existing.map(Self.progress)
        let newer = candidates.contains { candidate in
            guard Self.isFurther(candidate, than: progress) else { return false }
            return candidate.isCompleted != progress.isCompleted || candidate.revision > progress.revision
                || candidate.lastOpenedAt > progress.lastOpenedAt
        }
        // A delayed writer must never undo a newer revision or completion.
        guard !newer else { return false }
        let entity = existing.first ?? LessonProgressEntity(lessonId: lessonId, courseId: progress.courseID)
        if existing.isEmpty { modelContext.insert(entity) }
        for duplicate in existing.dropFirst() { modelContext.delete(duplicate) }
        entity.courseId = progress.courseID
        entity.revision = progress.revision
        entity.currentStep = progress.currentStep
        entity.answersData = try JSONEncoder().encode(progress.answers)
        entity.completedAt = progress.completedAt
        entity.lastOpenedAt = progress.lastOpenedAt
        entity.xp = progress.xp
        if saving { try modelContext.save() }
        return true
    }

    /// The oldest of each course, in case two devices each made one.
    private func readCertificates() throws -> [Certificate] {
        var byCourse: [String: Certificate] = [:]
        for entity in try modelContext.fetch(FetchDescriptor<CertificateEntity>(sortBy: [SortDescriptor(\.date)])) where byCourse[entity.courseId] == nil {
            byCourse[entity.courseId] = Certificate(courseID: entity.courseId, date: entity.date)
        }
        return byCourse.values.sorted { $0.date > $1.date }
    }

    private func writeCertificate(_ certificate: Certificate) throws {
        let courseId = certificate.courseID
        guard try modelContext.fetchCount(FetchDescriptor<CertificateEntity>(predicate: #Predicate { $0.courseId == courseId })) == 0 else {
            return
        }
        modelContext.insert(CertificateEntity(courseId: courseId, date: certificate.date))
        try modelContext.save()
    }

    static func progress(_ entity: LessonProgressEntity) throws -> LessonProgress {
        return try LessonProgress(lessonID: entity.lessonId, courseID: entity.courseId, currentStep: entity.currentStep,
                       answers: entity.answersData.isEmpty ? [:] : JSONDecoder().decode([Int: LessonAnswer].self, from: entity.answersData),
                       completedAt: entity.completedAt, lastOpenedAt: entity.lastOpenedAt, xp: entity.xp, revision: entity.revision)
    }

    static func isFurther(_ a: LessonProgress, than b: LessonProgress) -> Bool {
        if a.isCompleted != b.isCompleted { return a.isCompleted }
        if a.revision != b.revision { return a.revision > b.revision }
        return a.lastOpenedAt >= b.lastOpenedAt
    }
}

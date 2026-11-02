import Core
import Foundation
import SwiftData

/// `LearningRepository` on the Personal store. Two devices may each write a lesson before syncing, so reads keep
/// the furthest record of a lesson: completed first, then the one opened last.
@ModelActor
public actor LearningStore: LearningRepository {
    public func progress() throws -> [String: LessonProgress] {
        var byLesson: [String: LessonProgress] = [:]
        for entity in try modelContext.fetch(FetchDescriptor<LessonProgressEntity>()) {
            let progress = Self.progress(entity)
            if let kept = byLesson[progress.lessonID], Self.isFurther(kept, than: progress) { continue }
            byLesson[progress.lessonID] = progress
        }
        return byLesson
    }

    public func save(_ progress: LessonProgress) throws {
        let lessonId = progress.lessonID
        let existing = try modelContext.fetch(FetchDescriptor<LessonProgressEntity>(predicate: #Predicate { $0.lessonId == lessonId }))
        let entity = existing.first ?? LessonProgressEntity(lessonId: lessonId, courseId: progress.courseID)
        if existing.isEmpty { modelContext.insert(entity) }
        for duplicate in existing.dropFirst() { modelContext.delete(duplicate) }
        entity.courseId = progress.courseID
        entity.currentStep = progress.currentStep
        entity.answersData = (try? JSONEncoder().encode(progress.answers)) ?? Data()
        entity.completedAt = progress.completedAt
        entity.lastOpenedAt = progress.lastOpenedAt
        entity.xp = progress.xp
        try modelContext.save()
    }

    /// The oldest of each course, in case two devices each made one.
    public func certificates() throws -> [Certificate] {
        var byCourse: [String: Certificate] = [:]
        for entity in try modelContext.fetch(FetchDescriptor<CertificateEntity>(sortBy: [SortDescriptor(\.date)])) where byCourse[entity.courseId] == nil {
            byCourse[entity.courseId] = Certificate(courseID: entity.courseId, date: entity.date)
        }
        return byCourse.values.sorted { $0.date > $1.date }
    }

    public func addCertificate(_ certificate: Certificate) throws {
        let courseId = certificate.courseID
        guard try modelContext.fetchCount(FetchDescriptor<CertificateEntity>(predicate: #Predicate { $0.courseId == courseId })) == 0 else {
            return
        }
        modelContext.insert(CertificateEntity(courseId: courseId, date: certificate.date))
        try modelContext.save()
    }

    static func progress(_ entity: LessonProgressEntity) -> LessonProgress {
        LessonProgress(lessonID: entity.lessonId, courseID: entity.courseId, currentStep: entity.currentStep,
                       answers: (try? JSONDecoder().decode([Int: LessonAnswer].self, from: entity.answersData)) ?? [:],
                       completedAt: entity.completedAt, lastOpenedAt: entity.lastOpenedAt, xp: entity.xp)
    }

    static func isFurther(_ a: LessonProgress, than b: LessonProgress) -> Bool {
        if a.isCompleted != b.isCompleted { return a.isCompleted }
        return a.lastOpenedAt >= b.lastOpenedAt
    }
}

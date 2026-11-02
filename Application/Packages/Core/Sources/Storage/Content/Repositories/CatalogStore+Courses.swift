import Core
import Foundation
import SwiftData

/// `CourseCatalog` on the Content store.
extension CatalogStore: CourseCatalog {
    public func courses(_ kind: CourseKind) throws -> [Course] {
        let raw = kind.rawValue
        let descriptor = FetchDescriptor<ModuleEntity>(predicate: #Predicate { $0.kind == raw }, sortBy: [SortDescriptor(\.order)])
        return try modelContext.fetch(descriptor).compactMap(Self.course)
    }

    public func course(id: String) throws -> Course? {
        var descriptor = FetchDescriptor<ModuleEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.flatMap(Self.course)
    }

    public func lesson(id: String) throws -> Lesson? {
        var descriptor = FetchDescriptor<LessonEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        let steps = try JSONDecoder().decode([PackedStep].self, from: entity.stepsData).compactMap(\.step)
        return Lesson(summary: Self.summary(entity), steps: steps)
    }

    static func course(_ entity: ModuleEntity) -> Course? {
        guard let kind = CourseKind(rawValue: entity.kind) else { return nil }
        return Course(id: entity.id, kind: kind, order: entity.order, title: entity.title, about: entity.about,
                      level: entity.level, color: entity.color,
                      countries: kind == .region ? [entity.country].compactMap(\.self) : entity.countries,
                      countryCode: entity.countryCode, grapes: entity.grapes,
                      lessons: entity.lessons.sorted { $0.order < $1.order }.map(summary))
    }

    static func summary(_ entity: LessonEntity) -> LessonSummary {
        LessonSummary(id: entity.id, courseID: entity.moduleId, order: entity.order, title: entity.title,
                      subtitle: entity.subtitle, xp: entity.xp, minutes: entity.estimatedMinutes,
                      isReview: entity.isReview, objectives: entity.objectives)
    }
}

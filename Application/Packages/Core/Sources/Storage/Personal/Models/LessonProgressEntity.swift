import Foundation
import SwiftData

/// The progress of one lesson, in the Personal store (ARCHITECTURE §2.1, `LessonProgress`).
/// CloudKit: every field has a default and nothing is unique; the store keeps one per lessonId.
@Model
public final class LessonProgressEntity {
    public var lessonId = ""
    public var courseId = ""
    public var revision = 0
    public var currentStep = 0
    /// `[step index: LessonAnswer]` as JSON.
    public var answersData = Data()
    public var completedAt: Date?
    public var lastOpenedAt = Date.distantPast
    public var xp = 0

    init(lessonId: String, courseId: String) {
        self.lessonId = lessonId
        self.courseId = courseId
    }
}

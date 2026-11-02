import Foundation
import SwiftData

/// A lesson of a module, in the Content store. The steps stay as JSON until the lesson opens (LESSON.md).
@Model
public final class LessonEntity {
    #Unique<LessonEntity>([\.id])
    #Index<LessonEntity>([\.moduleId])

    public var id: String
    public var moduleId: String
    public var order: Int
    public var title: String
    public var subtitle: String
    public var xp: Int
    public var estimatedMinutes: Int
    public var isReview: Bool
    public var objectives: [String]
    /// The `steps` array of the lesson, as packed by pack_content.py.
    public var stepsData: Data
    public var module: ModuleEntity?

    init(id: String) {
        self.id = id
        self.moduleId = ""
        self.order = 0
        self.title = ""
        self.subtitle = ""
        self.xp = 0
        self.estimatedMinutes = 0
        self.isReview = false
        self.objectives = []
        self.stepsData = Data()
    }
}

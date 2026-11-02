import Foundation
import SwiftData

/// A Learn module: a step of the path, a grape or a region (LEARN.md), in the Content store.
@Model
public final class ModuleEntity {
    #Unique<ModuleEntity>([\.id])
    #Index<ModuleEntity>([\.kind, \.order])

    public var id: String
    /// path, grape or region.
    public var kind: String
    public var order: Int
    public var title: String
    /// The module's one-line description.
    public var about: String
    public var complexity: String
    public var lessonCount: Int
    public var xp: Int
    public var estimatedMinutes: Int
    /// Path only.
    public var level: String?
    /// Grape only: red or white.
    public var color: String?
    /// Grape only.
    public var origin: String?
    public var aliases: [String]
    public var countries: [String]
    /// Region only.
    public var country: String?
    public var countryCode: String?
    public var grapes: [String]
    public var points: String?
    @Relationship(deleteRule: .cascade, inverse: \LessonEntity.module)
    public var lessons: [LessonEntity]

    init(id: String) {
        self.id = id
        self.kind = ""
        self.order = 0
        self.title = ""
        self.about = ""
        self.complexity = ""
        self.lessonCount = 0
        self.xp = 0
        self.estimatedMinutes = 0
        self.aliases = []
        self.countries = []
        self.grapes = []
        self.lessons = []
    }
}

import Foundation

/// A Learn module or course: a step of The path, a grape or a region (LEARN-R01), with its lessons in order.
public struct Course: Identifiable, Equatable, Sendable {
    public var id: String
    public var kind: CourseKind
    /// The order inside its tab. Grapes: reds darkest first, then whites deepest first (LEARN-R08).
    public var order: Int
    public var title: String
    public var about: String
    /// Path only: Essentials, Intermediate, Advanced or Expert (LEARN-R10).
    public var level: String?
    /// Grape only: red or white.
    public var color: String?
    /// Grape: the countries it is known in. Region: its own country.
    public var countries: [String]
    /// Region only.
    public var countryCode: String?
    /// Region only: the grapes it grows.
    public var grapes: [String]
    public var lessons: [LessonSummary]

    public init(id: String, kind: CourseKind, order: Int, title: String, about: String, level: String? = nil,
                color: String? = nil, countries: [String] = [], countryCode: String? = nil, grapes: [String] = [],
                lessons: [LessonSummary]) {
        self.id = id
        self.kind = kind
        self.order = order
        self.title = title
        self.about = about
        self.level = level
        self.color = color
        self.countries = countries
        self.countryCode = countryCode
        self.grapes = grapes
        self.lessons = lessons
    }

    /// LEARN-R20: 15 XP a lesson, no bonus.
    public var xp: Int { lessons.reduce(0) { $0 + $1.xp } }
    public var minutes: Int { lessons.reduce(0) { $0 + $1.minutes } }

    public func lesson(after lesson: LessonSummary) -> LessonSummary? {
        lessons.first { $0.order > lesson.order }
    }

    public func lesson(before lesson: LessonSummary) -> LessonSummary? {
        lessons.last { $0.order < lesson.order }
    }
}

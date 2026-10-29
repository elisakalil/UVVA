import Foundation

struct Dish: Equatable, Sendable {
    var title: String
    var why: String
}

struct Wine: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    var origin: String
    var profile: PalateMap
    var dish: Dish?
    /// One or two lines on how it tastes, shown on the Home cards.
    var note: String? = nil
}

enum Verdict: String, Sendable { case yes, maybe, no }

/// One answer to "Would you drink it again?" and how it moved each axis (SHARED-R10).
struct Rating: Equatable, Sendable {
    var wineID: String
    var verdict: Verdict
    var date: Date
    var deltas: [Axis: Double]
}

struct Friend: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
    /// 0...100, comes from match.md (not written yet).
    var compatibility: Int
}

struct LessonRef: Equatable, Sendable {
    var number: Int
    var title: String
    var step: Int
}

/// Progress of a module or a region/grape course (LEARN-R01, LEARN-R02).
struct CourseProgress: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var totalLessons: Int
    var completedLessons: Int
    var hasStarted: Bool
    var lastOpenedAt: Date?
    var current: LessonRef?

    var isInProgress: Bool { hasStarted && completedLessons < totalLessons }
}

struct GlossaryTerm: Equatable, Sendable {
    var term: String
    var pronunciation: String
    var definition: String
}

struct AppNotification: Identifiable, Equatable, Sendable {
    var id: String
    var text: String
    var isRead: Bool
}

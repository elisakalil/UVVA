import Foundation

/// A Learn module as other features show it.
public struct CourseSummary: Equatable, Sendable {
    public var id: String
    public var title: String
    public var lessonCount: Int
    public var minutes: Int

    public init(id: String, title: String, lessonCount: Int, minutes: Int) {
        self.id = id
        self.title = title
        self.lessonCount = lessonCount
        self.minutes = minutes
    }
}

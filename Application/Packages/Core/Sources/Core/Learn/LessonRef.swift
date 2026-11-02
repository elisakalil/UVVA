import Foundation

public struct LessonRef: Equatable, Sendable {
    public var number: Int
    public var title: String
    public var step: Int

    public init(number: Int, title: String, step: Int) {
        self.number = number
        self.title = title
        self.step = step
    }
}

import Foundation

public struct Dish: Equatable, Sendable {
    public var title: String
    public var why: String

    public init(title: String, why: String) {
        self.title = title
        self.why = why
    }
}

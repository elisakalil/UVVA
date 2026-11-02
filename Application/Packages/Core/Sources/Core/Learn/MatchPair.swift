import Foundation

/// One pair of a matchPairs step: a term and its short match (LESSON.md §6).
public struct MatchPair: Equatable, Sendable {
    public var left: String
    public var right: String

    public init(left: String, right: String) {
        self.left = left
        self.right = right
    }
}

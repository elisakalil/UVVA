import Foundation

public struct GlossaryTerm: Equatable, Sendable {
    public var term: String
    public var pronunciation: String
    public var definition: String

    public init(term: String, pronunciation: String, definition: String) {
        self.term = term
        self.pronunciation = pronunciation
        self.definition = definition
    }
}

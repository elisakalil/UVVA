import Foundation

public struct GlossaryTerm: Equatable, Sendable {
    public var term: String
    public var pronunciation: String
    public var definition: String
    public var aka: String?
    public var lesson: Int?

    public init(term: String, pronunciation: String, definition: String, aka: String? = nil, lesson: Int? = nil) {
        self.term = term
        self.pronunciation = pronunciation
        self.definition = definition
        self.aka = aka
        self.lesson = lesson
    }
}

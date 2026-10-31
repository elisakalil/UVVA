import Foundation
import SwiftData

/// A glossary term (SHARED-R18), in the Content store.
@Model
public final class GlossaryTermEntity {
    #Unique<GlossaryTermEntity>([\.id])

    public var id: String
    public var term: String
    public var definition: String
    public var pronunciation: String?
    /// Other names for the term ("DOC · DO · AOC").
    public var aka: String?
    /// The lesson number the term comes from, as in the canvas.
    public var lesson: Int?

    init(id: String) {
        self.id = id
        self.term = ""
        self.definition = ""
    }
}

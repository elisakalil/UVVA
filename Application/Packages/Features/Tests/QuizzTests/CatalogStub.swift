import Core
import Foundation

/// A catalog of a few wines, for "Draw the map" (QUIZ-R04b).
struct CatalogStub: CatalogRepository {
    let wines: [Wine]

    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine] { Array(wines.prefix(limit)) }
    func recipes() async throws -> [Recipe] { [] }
    func glossary() async throws -> [GlossaryTerm] { [] }
    func firstPathModule() async throws -> CourseSummary? { nil }
}

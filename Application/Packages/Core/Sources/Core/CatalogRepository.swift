import Foundation

/// The Content store as the features read it.
public protocol CatalogRepository: Sendable {
    /// The `limit` wines most similar to the map (SHARED-R07), best first.
    func winesClosest(to map: PalateMap, limit: Int) async throws -> [Wine]
    func recipes() async throws -> [Recipe]
    func glossary() async throws -> [GlossaryTerm]
    /// The first module of The path, where a new learner starts (YOU-R07).
    func firstPathModule() async throws -> CourseSummary?
}

import Foundation

/// Keeps the Cellar in the Personal store (CELLAR.md).
public protocol CellarRepository: Sendable {
    /// Every entry, newest first by `createdAt` (CELLAR-R02).
    func entries() async throws -> [CellarEntry]
    /// Entries for browsing and searching, with label data omitted.
    func entrySummaries() async throws -> [CellarEntry]
    /// A single persisted entry, including both labels.
    func entry(_ wineKey: String) async throws -> CellarEntry?
    /// Front labels for the requested portion of the collection.
    func frontPhotos(for wineKeys: [String]) async throws -> [String: Data]
    /// The wineKeys of every entry, tasted or not.
    func wineKeys() async throws -> Set<String>
    /// Adds the wine as Want to try (CELLAR-R01). A wine already in the Cellar stays as it is, so a tasted
    /// entry is never turned back into Not yet.
    func addWantToTry(_ wine: Wine) async throws
    /// The wineKeys of the wines already rated (SHARED-R11).
    func tastedWineKeys() async throws -> Set<String>
    /// Keeps the wine as Tasted with its verdict (CELLAR-R13c). A wine already in the Cellar, Not yet or
    /// Tasted, is updated in place.
    func addTasted(_ wine: Wine, verdict: Verdict) async throws
    /// "Save note" or "Add to cellar" on a new note (CELLAR-R19, R13b). A wine already in the Cellar is updated in
    /// place: the facts, and the photos and note when the draft has them; a verdict replaces the old one, and a
    /// Tasted entry never goes back to Want to try. Returns the entry as it was before, nil when it is new.
    @discardableResult
    func save(_ draft: NewNoteDraft) async throws -> CellarEntry?
    /// "Save changes" on a note (CELLAR-R27): a verdict makes the entry Tasted; an empty note is cleared.
    func update(_ wineKey: String, verdict: Verdict?, note: String?) async throws
    /// "Delete" on a note (CELLAR-R28).
    func delete(_ wineKey: String) async throws
}

extension CellarRepository {
    public func entrySummaries() async throws -> [CellarEntry] {
        try await entries().map { entry in
            var summary = entry
            summary.photoFront = nil
            summary.photoBack = nil
            return summary
        }
    }

    public func entry(_ wineKey: String) async throws -> CellarEntry? {
        try await entries().first { $0.id == wineKey }
    }

    public func frontPhotos(for wineKeys: [String]) async throws -> [String: Data] {
        let keys = Set(wineKeys)
        var photos: [String: Data] = [:]
        for entry in try await entries() where keys.contains(entry.id) {
            photos[entry.id] = entry.photoFront
        }
        return photos
    }
}

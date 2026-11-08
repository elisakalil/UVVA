import Foundation

/// Replaces the current map's history after a rating was edited or deleted (CELLAR-R29, ARCHITECTURE §2.1).
public protocol PalateHistoryRewriting: Sendable {
    /// The history becomes `history`, and the current map its last entry's values. The first entry stays the Quiz.
    func rewriteHistory(_ history: [MapChange]) async throws
}

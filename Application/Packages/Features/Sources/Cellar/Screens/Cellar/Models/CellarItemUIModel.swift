import Foundation

/// One wine as a cover in the grid and as a row in the list (CELLAR-R06, R09).
public struct CellarItemUIModel: Identifiable, Equatable {
    public var id: String
    var name: String
    /// "2019", or empty for a wine without a vintage.
    var vintage: String
    /// "Douro · Portugal · Touriga Nacional".
    var meta: String
    /// Yes, Maybe, No or Not yet.
    var tag: String
    var photo: Data?
    var updatedAt: Date = .distantPast
    var cover: CellarCoverStyle
    var accessibilityLabel: String
}

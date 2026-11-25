import Foundation

/// One wine as a cover in the grid and as a row in the list (CELLAR-R06, R09).
public struct CellarItemUIModel: Identifiable, Equatable {
    public var id: String
    var name: String
    /// "2019", or empty for a wine without a vintage.
    var vintage: String
    /// "82% match", or empty without a map or a profile to compare.
    var match: String
    /// "82%", large by the name on a cover; empty as `match` is.
    var percent: String = ""
    /// The region, or the country when there is no region.
    var place: String
    /// Yes, Maybe, No or Not yet.
    var tag: String
    var photo: Data?
    var updatedAt: Date = .distantPast
    var cover: CellarCoverStyle
    var accessibilityLabel: String
}

import Core
import Foundation

/// Whether the user will likely enjoy a wine, and why, from the wine's map against theirs: the axes high on both,
/// and the one where they are furthest apart (`WineFit`).
public struct WineOutlook: Equatable, Sendable {
    public enum Lean: Equatable, Sendable { case likely, mixed, unlikely }

    public let lean: Lean
    /// Up to two axes high on both.
    public let shared: [PalateAxis]
    /// The axis furthest apart, when it is far enough to tell.
    public let apart: PalateAxis?
    /// The wine has more of `apart` than the map.
    public let hasMore: Bool

    /// At or above this match, the user will likely enjoy it.
    public static let likelyFrom = 80
    /// Below this match, it will likely not be for them.
    public static let unlikelyBelow = 65

    public init(wine: PalateMap, map: PalateMap) {
        let fit = WineFit(wine: wine, map: map)
        let percent = Similarity.percent(wine, map)
        lean = percent >= Self.likelyFrom ? .likely : percent < Self.unlikelyBelow ? .unlikely : .mixed
        shared = fit.shared
        apart = fit.apart
        hasMore = fit.apart.map { wine[$0] > map[$0] } ?? false
    }
}

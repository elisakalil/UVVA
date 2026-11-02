import Core
import Foundation

/// How the day's wine reads against the user's map (HOME-R10a, R10b). One reading for the whole card, so the
/// reason, the axes shown and the match never disagree.
public struct WineFit: Sendable {
    public let wine: PalateMap
    public let map: PalateMap

    /// Under this difference the wine counts as close to the map on an axis.
    public static let close = 1.8

    public init(wine: PalateMap, map: PalateMap) {
        self.wine = wine
        self.map = map
    }

    /// By the map's level, highest first; ties on the map go to what the wine is highest on, then the canonical order.
    public var ordered: [PalateAxis] {
        PalateAxis.allCases.enumerated()
            .sorted { lhs, rhs in
                let (l, r) = (MapReading.level(map[lhs.element]), MapReading.level(map[rhs.element]))
                if l != r { return l > r }
                if wine[lhs.element] != wine[rhs.element] { return wine[lhs.element] > wine[rhs.element] }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// The three axes the card reads the wine on.
    public var shown: [PalateAxis] { Array(ordered.prefix(3)) }

    /// The map's high axes, in `ordered`.
    public var mapHighs: [PalateAxis] { ordered.filter { AxisTone(map[$0]) == .high } }

    public var wineHasHigh: Bool { PalateAxis.allCases.contains { AxisTone(wine[$0]) == .high } }

    /// Up to two axes high on both.
    public var shared: [PalateAxis] { Array(mapHighs.filter { AxisTone(wine[$0]) == .high }.prefix(2)) }

    /// The axis where the two are furthest apart, when that is at least `close`; ties in the canonical order.
    public var apart: PalateAxis? {
        guard let far = PalateAxis.allCases.max(by: { abs(wine[$0] - map[$0]) < abs(wine[$1] - map[$1]) }),
              abs(wine[far] - map[far]) >= Self.close
        else { return nil }
        return far
    }
}

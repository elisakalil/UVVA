import Core
import Foundation

/// How the day's wine reads against the user's map (HOME-R10a, R10b). One reading for the whole card, so the
/// reason, the axes shown and the match never disagree.
public struct WineFit: Sendable {
    public let wine: PalateMap
    public let map: PalateMap

    /// Under this difference in position the wine counts as close to the map on an axis.
    public static let close = 1.8

    public init(wine: PalateMap, map: PalateMap) {
        self.wine = wine
        self.map = map
    }

    /// By the map's level (its position on the ruler), highest first; ties on the map go to what the wine stands out
    /// on most, then the canonical order.
    public var ordered: [PalateAxis] {
        PalateAxis.allCases.enumerated()
            .sorted { lhs, rhs in
                let (l, r) = (MapReading.level(map, lhs.element), MapReading.level(map, rhs.element))
                if l != r { return l > r }
                let (lw, rw) = (WineRuler.position(of: wine[lhs.element], on: lhs.element),
                                WineRuler.position(of: wine[rhs.element], on: rhs.element))
                if lw != rw { return lw > rw }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// The three axes the card reads the wine on.
    public var shown: [PalateAxis] { Array(ordered.prefix(3)) }

    /// The map's high axes, in `ordered`.
    public var mapHighs: [PalateAxis] { ordered.filter { AxisTone(map, $0) == .high } }

    public var wineHasHigh: Bool { PalateAxis.allCases.contains { AxisTone(wine, $0) == .high } }

    /// Up to two axes high on both.
    public var shared: [PalateAxis] { Array(mapHighs.filter { AxisTone(wine, $0) == .high }.prefix(2)) }

    /// The axis where the two are furthest apart in position, when that is at least `close`; ties in the canonical
    /// order.
    public var apart: PalateAxis? {
        let gap: (PalateAxis) -> Double = {
            abs(WineRuler.position(of: wine[$0], on: $0) - WineRuler.position(of: map[$0], on: $0))
        }
        guard let far = PalateAxis.allCases.max(by: { gap($0) < gap($1) }), gap(far) >= Self.close else { return nil }
        return far
    }
}

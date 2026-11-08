import Core
import Foundation

/// The palate map of a wine that is not in the catalog (CELLAR-R17): the average of the catalog wines most like it.
public enum ProfileEstimate {
    /// Narrowing to the region only when at least this many wines are left.
    static let minimumRegionWines = 3

    /// First the wines of the same type sharing the most grapes (of the region, when there are enough of them);
    /// failing that, the same type and region; then the same type; then the whole catalog. Nil only for an empty
    /// catalog.
    public static func estimate(grapes: [String], type: String?, region: String?, in wines: [Wine]) -> PalateMap? {
        let typed = type.map { type in wines.filter { $0.type == type } } ?? wines
        let regional: ([Wine]) -> [Wine]? = { pool in
            guard let region else { return nil }
            let inRegion = pool.filter { $0.region == region }
            return inRegion.count >= minimumRegionWines ? inRegion : nil
        }
        if !grapes.isEmpty {
            let wanted = Set(grapes)
            let overlaps = typed.map { (wine: $0, shared: wanted.intersection($0.grapes).count) }
            if let most = overlaps.map(\.shared).max(), most > 0 {
                let closest = overlaps.filter { $0.shared == most }.map(\.wine)
                return average(regional(closest) ?? closest)
            }
        }
        if let inRegion = regional(typed) { return average(inRegion) }
        return average(typed.isEmpty ? wines : typed)
    }

    private static func average(_ wines: [Wine]) -> PalateMap? {
        guard !wines.isEmpty else { return nil }
        let count = Double(wines.count)
        return PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { axis in
            (axis, wines.reduce(0) { $0 + $1.profile[axis] } / count)
        }))
    }
}

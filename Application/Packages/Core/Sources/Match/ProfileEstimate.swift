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

    /// CELLAR-R23a: the map of a wine read on a label or filled in by hand, only when there is something to draw it
    /// from: the type and at least one of a grape, a region, a tasting note or the time in wood that the catalog
    /// knows. Nil otherwise: without a base there is no map, not the catalog's average.
    ///
    /// The wines of that type sharing the most grapes (of the region, when there are enough of them); failing that,
    /// those of the region; then those sharing the most notes. The time in wood then sets the Oak axis; alone with
    /// the type, it sets it on the type's average.
    public static func estimate(_ facts: LabelFacts, in wines: [Wine]) -> PalateMap? {
        guard let type = facts.type, !wines.isEmpty else { return nil }
        let typed = wines.filter { $0.type == type }
        let pool = typed.isEmpty ? wines : typed
        var closest: [Wine]?
        if !facts.grapes.isEmpty {
            let shared = sharing(facts.grapes, in: pool, values: \.grapes)
            closest = shared.flatMap { wines in
                facts.region.flatMap { region in
                    let inRegion = wines.filter { $0.region == region }
                    return inRegion.count >= minimumRegionWines ? inRegion : nil
                } ?? wines
            }
        }
        if closest == nil, let region = facts.region {
            let inRegion = pool.filter { $0.region == region }
            closest = inRegion.isEmpty ? nil : inRegion
        }
        if closest == nil, !facts.notes.isEmpty {
            closest = sharing(facts.notes, in: pool, values: \.noteItems)
        }
        guard closest != nil || facts.oakAging != nil, var map = average(closest ?? pool) else { return nil }
        if let oak = facts.oakAging {
            var values = map.values
            values[.oak] = oak.oakIntensity
            map = PalateMap(values)
        }
        return map
    }

    /// The wines sharing the most of `wanted`, whatever the case; nil when none shares any.
    private static func sharing(_ wanted: [String], in wines: [Wine], values: (Wine) -> [String]) -> [Wine]? {
        let wanted = Set(wanted.map { $0.lowercased() })
        let overlaps = wines.map { wine in (wine: wine, shared: wanted.intersection(values(wine).map { $0.lowercased() }).count) }
        guard let most = overlaps.map(\.shared).max(), most > 0 else { return nil }
        return overlaps.filter { $0.shared == most }.map(\.wine)
    }

    private static func average(_ wines: [Wine]) -> PalateMap? {
        guard !wines.isEmpty else { return nil }
        let count = Double(wines.count)
        return PalateMap(Dictionary(uniqueKeysWithValues: PalateAxis.allCases.map { axis in
            (axis, wines.reduce(0) { $0 + $1.profile[axis] } / count)
        }))
    }
}

import Core
import Foundation
import Synchronization

public extension QualityPrevalence {
    private static let stored = Mutex<QualityPrevalence?>(nil)

    /// The shares of the last snapshot of the public catalog the app read (ARCHITECTURE §4.1), or those of the seed
    /// until there is one.
    static var current: QualityPrevalence {
        stored.withLock { $0 } ?? .packed
    }

    /// Makes these the shares every certificate uses from now on.
    static func use(_ prevalence: QualityPrevalence) {
        stored.withLock { $0 = prevalence }
    }

    /// The share of these wines at each level of appellation and legal term or above, the catalog standing for the
    /// world's wines (CELLAR-R30); recognition stays assumed, as the catalog has few medals. The same count as
    /// `quality_prevalence` in `pack_content.py`.
    static func measure(_ wines: [Wine], recognition: [String: Double] = QualityPrevalence.packed.recognition)
        -> QualityPrevalence? {
        guard !wines.isEmpty else { return nil }
        let tiers = wines.map { Certification.tier(of: $0)?.rawValue ?? 0 }
        let strengths = wines.map { Certification.strength(of: $0)?.rawValue ?? 0 }
        func shares(_ levels: [Int], names: [(String, Int)]) -> [String: Double] {
            Dictionary(uniqueKeysWithValues: names.map { name, value in
                let share = Double(levels.filter { $0 >= value }.count) / Double(levels.count)
                return (name, (share * 10_000).rounded() / 10_000)
            })
        }
        return QualityPrevalence(
            appellation: shares(tiers, names: [("regional", AppellationTier.regional.rawValue),
                                               ("protected", AppellationTier.protected.rawValue),
                                               ("top", AppellationTier.top.rawValue)]),
            designation: shares(strengths, names: [("weak", DesignationStrength.weak.rawValue),
                                                   ("aged", DesignationStrength.aged.rawValue),
                                                   ("strong", DesignationStrength.strong.rawValue)]),
            recognition: recognition)
    }
}

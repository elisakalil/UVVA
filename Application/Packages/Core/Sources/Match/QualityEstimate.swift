import Core
import Foundation

/// The share of the world's wines at each level of the three criteria or above (CELLAR-R30): appellation and legal
/// term measured on the catalog, recognition assumed (the catalog has no medals). The robot measures them on every
/// snapshot of the public catalog and the app keeps the last ones (`QualityPrevalence.current`); `pack_content.py`
/// writes the numbers of the seed as code (`QualityPrevalence.packed`), so there are always some in the app.
public struct QualityPrevalence: Codable, Equatable, Sendable {
    public var appellation: [String: Double]
    public var designation: [String: Double]
    public var recognition: [String: Double]

    public init(appellation: [String: Double], designation: [String: Double], recognition: [String: Double]) {
        self.appellation = appellation
        self.designation = designation
        self.recognition = recognition
    }

    func share(_ tier: AppellationTier?) -> Double {
        switch tier {
        case .top: appellation["top"] ?? 1
        case .protected: appellation["protected"] ?? 1
        case .regional: appellation["regional"] ?? 1
        case nil: 1
        }
    }

    func share(_ strength: DesignationStrength?) -> Double {
        switch strength {
        case .strong: designation["strong"] ?? 1
        case .aged: designation["aged"] ?? 1
        case .weak: designation["weak"] ?? 1
        case nil: 1
        }
    }

    func share(recognition level: Int) -> Double {
        level > 0 ? recognition[String(level)] ?? 1 : 1
    }
}

/// "Top X% of the world's wines" (CELLAR-R30): the share of the world's wines with signals at least as strong as this
/// wine's on all three criteria, taken as independent. Shown only in the top 10 %, so it stays a mark of note.
public enum QualityEstimate {
    /// Above this, the card leads with the appellation's level in plain words instead.
    public static let shownUpTo = 10

    public static func topPercent(tier: AppellationTier?, strength: DesignationStrength?, recognition: Int,
                                  prevalence: QualityPrevalence) -> Int? {
        guard tier != nil || strength != nil || recognition > 0 else { return nil }
        let share = prevalence.share(tier) * prevalence.share(strength) * prevalence.share(recognition: recognition)
        let percent = rounded(share * 100)
        return percent <= shownUpTo ? percent : nil
    }

    /// Under 1 % is 1; up to 10 %, whole numbers; above, steps of five.
    static func rounded(_ percent: Double) -> Int {
        if percent < 1 { return 1 }
        if percent <= 10 { return max(1, Int(percent.rounded())) }
        return Int((percent / 5).rounded()) * 5
    }
}

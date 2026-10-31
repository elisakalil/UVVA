import Foundation

/// One answer to "Would you drink it again?" and how it moved each axis (SHARED-R10).
public struct Rating: Equatable, Sendable {
    public var wineKey: String
    public var verdict: Verdict
    public var date: Date
    public var deltas: [PalateAxis: Double]

    public init(wineKey: String, verdict: Verdict, date: Date, deltas: [PalateAxis: Double]) {
        self.wineKey = wineKey
        self.verdict = verdict
        self.date = date
        self.deltas = deltas
    }
}

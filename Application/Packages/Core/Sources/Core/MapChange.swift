import Foundation

/// One entry of the map's history: the map after a change and what caused it (ARCHITECTURE §2.1).
public struct MapChange: Codable, Equatable, Sendable {
    public var date: Date
    public var cause: MapChangeCause
    public var values: [PalateAxis: Double]

    public init(date: Date, cause: MapChangeCause, values: [PalateAxis: Double]) {
        self.date = date
        self.cause = cause
        self.values = values
    }
}

import Foundation

/// One entry of the map's history: the map after a change and what caused it (ARCHITECTURE §2.1).
public struct MapChange: Codable, Equatable, Sendable {
    public var date: Date
    public var cause: MapChangeCause
    public var values: [PalateAxis: Double]
    /// The Quiz only: the answers the map was drawn from, never shown, and the `WineRuler.version` it was drawn on,
    /// so the map can be drawn again if the ruler changes (QUIZ-R04a).
    public var answers: [PalateAxis: Int]?
    public var rulerVersion: Int?

    public init(date: Date, cause: MapChangeCause, values: [PalateAxis: Double],
                answers: [PalateAxis: Int]? = nil, rulerVersion: Int? = nil) {
        self.date = date
        self.cause = cause
        self.values = values
        self.answers = answers
        self.rulerVersion = rulerVersion
    }
}

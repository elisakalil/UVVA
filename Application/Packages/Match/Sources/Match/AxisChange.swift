import Core

/// One axis before and after a rating (QUIZ-R23, SHARED-R10).
public struct AxisChange: Equatable, Sendable {
    /// Smallest change that counts as the axis going up or down.
    public static let threshold = 0.05

    public var axis: PalateAxis
    public var before: Double
    public var after: Double

    public init(axis: PalateAxis, before: Double, after: Double) {
        self.axis = axis
        self.before = before
        self.after = after
    }

    public var delta: Double { after - before }
    public var wentUp: Bool { delta >= Self.threshold }
    public var wentDown: Bool { delta <= -Self.threshold }
}

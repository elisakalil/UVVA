import Core
import Foundation

/// The catalog wine a label was matched to (CELLAR-R17).
public struct LabelMatchResult: Equatable, Sendable {
    /// The catalog wine; with another vintage on the label, the same wine with that vintage and its own wineKey.
    public var wine: Wine
    /// 0...1.
    public var score: Double
    /// Sure enough to go straight to the note; otherwise the person checks the facts first (decision L2).
    public var isConfident: Bool
}

import Foundation

/// Which photo a line of the label was read from (CELLAR-R16).
public enum LabelSide: String, Codable, Sendable {
    case front, back
}

import Foundation

extension String {
    /// "Acidity · Spice · Sweetness" with the space before each dot made unbreakable,
    /// so a wrapped line ends with the dot instead of starting with it.
    public var keepingDotsAtLineEnd: String { replacingOccurrences(of: " · ", with: "\u{00A0}· ") }
}

import Foundation

/// One run of text read on a photo of a wine list, with where it sits on the page (WINELIST-R03). The page runs from
/// 0 to 1 on both sides, from the top left: the parser puts a wine's name and its price, read apart, back on one row.
public struct WineListLine: Equatable, Codable, Sendable {
    public var text: String
    public var minX: Double
    public var minY: Double
    public var width: Double
    public var height: Double
    /// How sure the text recognizer is, 0...1.
    public var confidence: Double

    public init(_ text: String, minX: Double = 0, minY: Double, width: Double = 1, height: Double = 0.02,
                confidence: Double = 1) {
        self.text = text
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
        self.confidence = confidence
    }

    public var midY: Double { minY + height / 2 }
    public var maxX: Double { minX + width }
}

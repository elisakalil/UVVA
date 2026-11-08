import Foundation

/// One line of text read on a label photo.
public struct LabelLine: Equatable, Sendable {
    public var text: String
    public var side: LabelSide
    /// The height of the line against the photo, 0...1: the bigger the type, the likelier it is the name or the
    /// producer.
    public var height: Double
    /// How sure the text recognizer is, 0...1.
    public var confidence: Double

    public init(_ text: String, side: LabelSide = .front, height: Double = 0.05, confidence: Double = 1) {
        self.text = text
        self.side = side
        self.height = height
        self.confidence = confidence
    }
}

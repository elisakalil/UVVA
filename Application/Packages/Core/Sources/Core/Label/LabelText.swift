import Foundation

/// Everything read on the front and back label photos.
public struct LabelText: Equatable, Sendable {
    public var lines: [LabelLine]

    public init(_ lines: [LabelLine]) {
        self.lines = lines
    }

    public var front: [LabelLine] { lines.filter { $0.side == .front } }
    public var back: [LabelLine] { lines.filter { $0.side == .back } }

    /// Nothing worth reading: no line with a letter in it.
    public var isEmpty: Bool { !lines.contains { $0.text.contains(where: \.isLetter) } }
}

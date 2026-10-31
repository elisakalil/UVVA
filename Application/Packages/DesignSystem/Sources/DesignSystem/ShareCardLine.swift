import Foundation

/// A tagged line at the foot of a share card ("LOVES  Elisa drinks for…").
public struct ShareCardLine: Equatable, Sendable {
    public var tag: String
    public var text: String

    public init(tag: String, text: String) {
        self.tag = tag
        self.text = text
    }
}

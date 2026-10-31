import Foundation

public struct Friend: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    /// 0...100, from MATCH.md.
    public var compatibility: Int

    public init(id: String, name: String, compatibility: Int) {
        self.id = id
        self.name = name
        self.compatibility = compatibility
    }
}

import Foundation

public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case learn = "Learn", cellar = "Cellar", home = "Home", friends = "Friends", you = "You"
    public var id: String { rawValue }

    /// The id its tab bar item publishes with `spotlightAnchor`.
    public var spotlightID: String { "tab.\(rawValue.lowercased())" }
}

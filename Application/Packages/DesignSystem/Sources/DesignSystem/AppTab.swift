import Foundation

public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case learn = "Learn", cellar = "Cellar", home = "Home", friends = "Friends", you = "You"
    public var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .learn: String(localized: "Learn", bundle: .module)
        case .cellar: String(localized: "Cellar", bundle: .module)
        case .home: String(localized: "Home", bundle: .module)
        case .friends: String(localized: "Friends", bundle: .module)
        case .you: String(localized: "You", bundle: .module)
        }
    }

    /// The id its tab bar item publishes with `spotlightAnchor`.
    public var spotlightID: String { "tab.\(rawValue.lowercased())" }
}

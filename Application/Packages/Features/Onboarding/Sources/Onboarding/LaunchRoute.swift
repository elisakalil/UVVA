import Core
import Foundation

/// Where the app goes after the Splash (ONB-R02).
public enum LaunchRoute: Equatable, Sendable {
    case welcome
    case quiz(firstName: String)
    case home

    /// ONB-R02, R27: no session → Welcome; a session without a map → the Quiz; with a map → Home.
    public static func resolve(profile: Profile?, hasMap: Bool) -> LaunchRoute {
        guard let profile else { return .welcome }
        return hasMap ? .home : .quiz(firstName: profile.firstName)
    }
}

import Core
import Foundation

/// How the Onboarding ended (ONB-R21, R27).
public enum OnboardingResult: Equatable, Sendable {
    /// A new account: the Quiz comes next.
    case newAccount(Profile)
    /// An account found in iCloud.
    case existingAccount(Profile, hasMap: Bool)
}

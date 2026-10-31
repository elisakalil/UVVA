import Foundation

/// The screens of the Onboarding (ONBOARDING.md §2). The Splash belongs to every launch and lives with the app.
public enum OnboardingStep: Equatable, Sendable {
    case welcome
    case legal(LegalTab)
    /// Waiting for iCloud to bring an existing account after the sign-in (ONB-R27).
    case lookingUpAccount
    case name
    case phone
    case findFriends
    case contacts
    case done
}

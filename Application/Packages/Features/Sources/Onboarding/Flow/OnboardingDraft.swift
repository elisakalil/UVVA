import Core
import Observation

/// Unsaved sign-up data shared by Name and Phone. A profile exists only after saving succeeds.
@MainActor @Observable
final class OnboardingDraft {
    var identity: AuthIdentity?
    var name = ""
    var profile: Profile?
}

import Core
import Combine

/// Unsaved sign-up data shared by Name and Phone. A profile exists only after saving succeeds.
@MainActor
final class OnboardingDraft: ObservableObject {
    @Published var identity: AuthIdentity?
    @Published var name = ""
    @Published var profile: Profile?
}

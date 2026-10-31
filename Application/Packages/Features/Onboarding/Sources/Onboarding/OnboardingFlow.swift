import Foundation

/// The Onboarding as a pure state machine (ONB-R02a, R20, R21, R27, R36a).
struct OnboardingFlow: Equatable, Sendable {
    private(set) var step: OnboardingStep = .welcome

    /// "Terms" or "Privacy Policy" on the Welcome (ONB-R28).
    mutating func openLegal(_ tab: LegalTab) {
        guard step == .welcome else { return }
        step = .legal(tab)
    }

    /// Signed in: look for the account in iCloud first (ONB-R27).
    mutating func signedIn() {
        guard step == .welcome else { return }
        step = .lookingUpAccount
    }

    /// The look-up ended. An existing account leaves the Onboarding; a new one asks the name.
    mutating func accountLookedUp(exists: Bool) {
        guard step == .lookingUpAccount else { return }
        step = exists ? .done : .name
    }

    /// Name → Phone → (session starts) → Find friends.
    mutating func next() {
        switch step {
        case .name: step = .phone
        case .phone: step = .findFriends
        case .contacts: step = .done
        default: break
        }
    }

    /// ONB-R36a: with access, the contacts; without, the Quiz.
    mutating func contactsAnswered(granted: Bool) {
        guard step == .findFriends else { return }
        step = granted ? .contacts : .done
    }

    /// ONB-R20. Find friends has no back: the session has started.
    mutating func back() {
        switch step {
        case .legal, .name: step = .welcome
        case .phone: step = .name
        case .contacts: step = .findFriends
        default: break
        }
    }

    var canGoBack: Bool {
        switch step {
        case .legal, .name, .phone, .contacts: true
        default: false
        }
    }
}

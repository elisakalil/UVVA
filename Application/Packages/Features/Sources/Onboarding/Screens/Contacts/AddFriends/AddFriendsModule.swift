import Core
import DesignSystem
import Foundation
import SwiftUI

/// The Contacts screen of the Onboarding (ONB-R37), opened again from the Friends tab once the user has an account
/// (FRI-R06): the same list, who is on UVVA to add and who to invite, closed by `‹` or "Done".
@MainActor
public final class AddFriendsModule: Identifiable {
    public let id = UUID()
    let contacts: ContactsViewModel
    /// Kept here: the screen holds its coordinator weakly.
    private let coordinator: AddFriendsCoordinator

    init(contacts: ContactsViewModel, coordinator: AddFriendsCoordinator) {
        self.contacts = contacts
        self.coordinator = coordinator
    }
}

/// Outside the Onboarding, Contacts only ever closes.
@MainActor
final class AddFriendsCoordinator: OnboardingCoordinatorProtocol {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) { self.onClose = onClose }

    func back() { onClose() }
    func finishContacts() { onClose() }
    func openLegal(_ tab: LegalTab) {}
    func signedIn(_ identity: AuthIdentity) {}
    func accountLookedUp(_ account: ExistingOnboardingAccount?) {}
    func continueFromName() {}
    func accountCreated(_ profile: Profile) {}
    func contactsAnswered(granted: Bool) {}
}

/// Contacts over the same softened photo as in the Onboarding.
public struct AddFriendsView: View {
    private let module: AddFriendsModule

    public init(module: AddFriendsModule) {
        self.module = module
    }

    public var body: some View {
        ZStack {
            PageBackground(photoOpacity: OnboardingView.photoOpacity, blur: 7)
            LinearGradient(colors: [Color(hex: 0x181E12).opacity(0.2), Color(hex: 0x181E12).opacity(0.5)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ContactsView(viewModel: module.contacts)
        }
        .foregroundStyle(UVVAColor.creamFill)
    }
}

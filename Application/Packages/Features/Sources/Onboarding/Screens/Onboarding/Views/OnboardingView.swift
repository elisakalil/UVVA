import DesignSystem
import SwiftUI

/// The Onboarding, from the Welcome to Contacts.
public struct OnboardingView: View {
    private let module: OnboardingModule

    /// How much of the vineyard photo shows over the moss, on every Onboarding screen and the Splash.
    static let photoOpacity = 0.95
    /// The black shade over the photo on Name and Phone. Black, not moss: moss turns the faded photo yellowish.
    static let dimOpacity = 0.45

    public init(module: OnboardingModule) {
        self.module = module
    }

    public var body: some View {
        ZStack {
            // The photo almost whole, so the moss under it doesn't tint the page.
            // Contacts softens it like the Quiz result ("Your taste is"), under a lighter shade.
            let isContacts = module.coordinator.step == .contacts
            PageBackground(photoOpacity: Self.photoOpacity, blur: isContacts ? 7 : 0)
            if isContacts {
                LinearGradient(colors: [Color(hex: 0x181E12).opacity(0.2), Color(hex: 0x181E12).opacity(0.5)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            if module.coordinator.step == .name || module.coordinator.step == .phone {
                Color.black.opacity(Self.dimOpacity)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            switch module.coordinator.step {
            case .welcome:
                WelcomeView(viewModel: module.welcome)
            case let .legal(tab):
                LegalView(tab: tab, onBack: { withAnimation(.smooth) { module.coordinator.back() } })
            case .lookingUpAccount, .done:
                GrapeLoop().frame(width: 100, height: 140)
            case .name:
                NameView(viewModel: module.name)
            case .phone:
                PhoneView(viewModel: module.phone)
            case .findFriends:
                FindFriendsView(viewModel: module.findFriends)
            case .contacts:
                ContactsView(viewModel: module.contacts)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .animation(.smooth, value: module.coordinator.step)
        .task { await module.welcome.checkICloud() }
    }
}

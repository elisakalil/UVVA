import DesignSystem
import SwiftUI

/// The Onboarding, from the Welcome to Contacts.
public struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel

    /// How much of the vineyard photo shows over the moss, on every Onboarding screen and the Splash.
    static let photoOpacity = 0.95

    public init(viewModel: OnboardingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            // The photo almost whole, so the moss under it doesn't tint the page.
            // Contacts softens it like the Quiz result ("Your taste is"), under a lighter shade.
            let isContacts = viewModel.step == .contacts
            PageBackground(photoOpacity: Self.photoOpacity, blur: isContacts ? 7 : 0)
            if isContacts {
                LinearGradient(colors: [Color(hex: 0x181E12).opacity(0.2), Color(hex: 0x181E12).opacity(0.5)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            switch viewModel.step {
            case .welcome:
                WelcomeView(viewModel: viewModel)
            case let .legal(tab):
                LegalView(tab: tab, onBack: { withAnimation(.smooth) { viewModel.back() } })
            case .lookingUpAccount, .done:
                GrapeLoop().frame(width: 100, height: 140)
            case .name:
                NameView(viewModel: viewModel)
            case .phone:
                PhoneView(viewModel: viewModel)
            case .findFriends:
                FindFriendsView(viewModel: viewModel)
            case .contacts:
                ContactsView(viewModel: viewModel)
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .animation(.smooth, value: viewModel.step)
        .task { await viewModel.checkICloud() }
    }
}

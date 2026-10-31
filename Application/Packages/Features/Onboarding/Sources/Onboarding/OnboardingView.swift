import DesignSystem
import SwiftUI

/// The Onboarding, from the Welcome to Contacts.
public struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            PageBackground(photoOpacity: 0.5)
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

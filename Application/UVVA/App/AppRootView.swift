import DesignSystem
import Features
import SwiftUI

/// Shows the screen the coordinator chose.
struct AppRootView: View {
    var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            switch coordinator.route {
            case .launching:
                SplashView()
            case .onboarding:
                if let onboarding = coordinator.onboarding { OnboardingView(viewModel: onboarding) }
            case .quiz:
                if let quiz = coordinator.quiz { QuizView(viewModel: quiz) }
            case .tabs:
                RootTabView(coordinator: coordinator)
            }
        }
        .animation(.smooth, value: coordinator.route)
        .task { await coordinator.start() }
    }
}

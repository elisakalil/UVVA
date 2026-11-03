import DesignSystem
import Foundation
import Onboarding
import Quizz
import SwiftUI

struct AppRootView: View {
    @State private var coordinator: AppCoordinator?
    @State private var failure: String?
    @State private var attempt = 0
    @State private var isStarting = false
    @State private var isRetrying = false

    private var errorMessage: String? {
        failure ?? coordinator?.launchError
    }

    var body: some View {
        ZStack {
            if let errorMessage {
                VStack(spacing: 16) {
                    Text("Could not open UVVA")
                        .font(.headline)

                    Text(errorMessage)
                        .multilineTextAlignment(.center)

                    Button("Try again") {
                        Task { await retry() }
                    }
                    .disabled(isRetrying)
                }
                .padding()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .background(
                    UVVAColor.moss.ignoresSafeArea()
                )
            } else {
                switch coordinator?.route {
                case nil, .launching:
                    SplashView()

                case .onboarding:
                    if let model = coordinator?.onboarding {
                        OnboardingView(viewModel: model)
                    }

                case .quiz:
                    if let model = coordinator?.quiz {
                        QuizView(viewModel: model)
                    }

                case .tabs:
                    if let coordinator {
                        RootTabView(coordinator: coordinator)
                    }
                }
            }
        }
        .animation(.smooth, value: coordinator?.route)
        .task(id: attempt) {
            await start()
        }
    }

    @MainActor
    private func start() async {
        guard coordinator == nil, !isStarting else { return }

        isStarting = true
        defer { isStarting = false }

        var content: ContentLoader?

        do {
            async let minimum: Void = Task.sleep(
                for: AppCoordinator.minimumSplash
            )

            async let fonts: Void = Task.detached(
                priority: .userInitiated
            ) {
                UVVAFont.register()
            }.value

            async let glass: Void = GlassTextures.prepare()

            let container = try await ContentLoader.openStores()
            let stores = await AppStores.make(container: container)

            try Task.checkCancellation()

            let loader = try ContentLoader(container: container)
            content = loader

            let candidate = AppCoordinator(
                stores: stores,
                content: loader
            )

            try await withTaskCancellationHandler {
                try await candidate.start()
            } onCancel: {
                loader.cancel()
            }

            await fonts
            await glass
            try await minimum
            try Task.checkCancellation()

            coordinator = candidate
        } catch is CancellationError {
            await content?.stop()
        } catch {
            await content?.stop()
            failure = error.localizedDescription
        }
    }

    @MainActor
    private func retry() async {
        guard !isRetrying else { return }

        isRetrying = true
        defer { isRetrying = false }

        await coordinator?.stop()

        coordinator = nil
        failure = nil
        attempt += 1
    }
}

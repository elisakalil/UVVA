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
    /// The screen under the Splash has been shown. The Splash leaves by fading out over a screen already drawn and
    /// still: the Home faded in under an opacity animation had its whole tree of glass panes (blurs, masks, Liquid
    /// Glass) drawn again offscreen on every frame, while it was still laying out, and the fade crawled on a phone.
    @State private var revealed = false
    /// The glass is drawn during the Splash at the screen's own scale.
    @Environment(\.displayScale) private var displayScale

    private var errorMessage: String? {
        failure ?? coordinator?.launchError
    }

    private var isLaunching: Bool {
        coordinator == nil || coordinator?.route == .launching
    }

    private var showsSplash: Bool {
        errorMessage == nil && (isLaunching || !revealed)
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
                    // The Splash is drawn above, so it can stay over the next screen until that one is ready.
                    Color.clear

                case .onboarding:
                    if let model = coordinator?.onboarding {
                        OnboardingView(module: model)
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

            if showsSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        // From a screen to the Splash (onboarding to quiz, quiz to tabs), the two cross-fade. Out of the Splash, the
        // next screen comes in at once, under it, and `reveal()` fades the Splash out once that screen is drawn.
        .animation(revealed ? .smooth : nil, value: coordinator?.route)
        .task(id: attempt) {
            await start()
        }
        .task(id: isLaunching) {
            if isLaunching {
                revealed = false
            } else {
                await reveal()
            }
        }
    }

    /// Fades the Splash out once the screen under it has laid out and been drawn (the glass of the Home takes its
    /// backdrop from a second layout pass). The work that can wait (prefetching the other tabs, the catalog sync,
    /// the contributions) starts when the fade is over, so it does not take its frames.
    @MainActor
    private func reveal() async {
        guard !revealed else { return }
        // Wakes only once the main thread is free again, so after the new screen's first commit.
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled, !isLaunching else { return }
        withAnimation(.easeOut(duration: 0.45)) {
            revealed = true
        } completion: {
            coordinator?.splashRevealed()
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

            async let glass: Void = GlassTextures.prepare(scale: displayScale)

            let container = try await ContentLoader.openStores()
            let stores = await AppStores.make(container: container)

            try Task.checkCancellation()

            let loader = try ContentLoader(container: container, stores: stores)
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

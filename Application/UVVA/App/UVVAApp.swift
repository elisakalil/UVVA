import DesignSystem
import Onboarding
import SwiftData
import SwiftUI

@main
struct UVVAApp: App {
    @State private var content: ContentLoader?
    @State private var coordinator: AppCoordinator?

    init() {
        UVVAFont.register()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let content, let coordinator {
                    AppRootView(coordinator: coordinator)
                        .modelContainer(content.container)
                        .environment(content)
                        .task { await content.load() }
                        .onChange(of: content.isReady) { _, ready in if ready { coordinator.contentDidLoad() } }
                } else {
                    // Drawn at once, while the stores open in the background.
                    SplashView()
                }
            }
            .preferredColorScheme(.dark)
            .task {
                guard content == nil else { return }
                let container = await ContentLoader.openStores()
                content = ContentLoader(container: container)
                coordinator = AppCoordinator(container: container)
            }
        }
    }
}

import DesignSystem
import Onboarding
import SwiftUI
import OSLog

@main
struct UVVAApp: App {
    @State private var content: ContentLoader?
    @State private var coordinator: AppCoordinator?

    var body: some Scene {
        WindowGroup {
            Group {
                if let content, let coordinator {
                    AppRootView(coordinator: coordinator)
                        .environment(content)
                        .task { await content.load() }
                        .onChange(of: content.isReady) { _, ready in if ready { coordinator.contentDidLoad() } }
                } else {
                    SplashView()
                }
            }
            .preferredColorScheme(.dark)
            .task {
                guard content == nil else { return }
                
                async let fonts = Task.detached { UVVAFont.register() }.value
                let container = await ContentLoader.openStores()
                let stores = await AppStores.make(container: container)
                
                await fonts
                content = ContentLoader(container: container)
                coordinator = AppCoordinator(stores: stores)
            }
        }
    }
}

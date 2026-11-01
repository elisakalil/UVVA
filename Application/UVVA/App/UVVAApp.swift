import DesignSystem
import Onboarding
import SwiftUI
import OSLog
let timingLog = Logger(subsystem: "app.uvva", category: "TIMING")

@main
struct UVVAApp: App {
    @State private var content: ContentLoader?
    @State private var coordinator: AppCoordinator?

    init() {
        timingLog.info("TIMING app init")
        UVVAFont.register()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let content, let coordinator {
                    // No `.modelContainer` here: its main context would merge every save of the content import on
                    // the main thread, freezing the Splash and the Welcome. The stores read through their own actors.
                    AppRootView(coordinator: coordinator)
                        .environment(content)
                        .task { await content.load() }
                        .onChange(of: content.isReady) { _, ready in if ready { coordinator.contentDidLoad() } }
                } else {
                    // Drawn at once, while the stores open in the background.
                    SplashView().onAppear { timingLog.info("TIMING outer splash appear") }
                }
            }
            .preferredColorScheme(.dark)
            .task {
                guard content == nil else { return }
                timingLog.info("TIMING task start")
                let container = await ContentLoader.openStores()
                timingLog.info("TIMING container open")
                let stores = await AppStores.make(container: container)
                timingLog.info("TIMING stores made")
                content = ContentLoader(container: container)
                coordinator = AppCoordinator(stores: stores)
            }
        }
    }
}

import DesignSystem
import SwiftData
import SwiftUI

@main
struct UVVAApp: App {
    @State private var content: ContentLoader
    @State private var coordinator: AppCoordinator

    init() {
        UVVAFont.register()
        let content = ContentLoader()
        _content = State(initialValue: content)
        _coordinator = State(initialValue: AppCoordinator(container: content.container))
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(coordinator: coordinator)
                .preferredColorScheme(.dark)
                .modelContainer(content.container)
                .environment(content)
                .task { await content.load() }
        }
    }
}

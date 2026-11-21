import SwiftUI

@main
struct UVVAApp: App {
    /// FRI-R11c: the pushes of the wines friends send.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
        }
    }
}

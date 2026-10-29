import SwiftUI

@main
struct UVVAApp: App {
    init() {
        UVVAFont.register()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
        }
    }
}

/// The five tabs with the design system's floating tab bar, about 40 pt from the bottom of the screen.
/// Only Home exists for now.
struct RootTabView: View {
    @State private var tab: AppTab = .home
    @State private var backdropFrame: CGRect?

    var body: some View {
        Group {
            switch tab {
            case .home: HomeView()
            default: Placeholder(name: tab.rawValue)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            UVVATabBar(active: $tab)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity)
        }
        // The page photo fills the window; the glass reads this to line its blurred copy up with it.
        // Measured before ignoresSafeArea, so the frame is the whole window and not just the safe area.
        .background {
            Color.clear
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { backdropFrame = $0 }
                .ignoresSafeArea()
        }
        .environment(\.backdropFrame, tab == .home ? backdropFrame : nil)
    }
}

private struct Placeholder: View {
    var name: String
    var body: some View {
        ZStack {
            UVVAColor.moss.ignoresSafeArea()
            Text(name).font(UVVAFont.sans(31, .ultraLight)).foregroundStyle(UVVAColor.cream)
        }
    }
}

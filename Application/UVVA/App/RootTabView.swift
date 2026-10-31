import DesignSystem
import Home
import SwiftUI
import You

/// The five tabs with the design system's floating tab bar, about 40 pt from the bottom of the screen,
/// and the Home tour over all of it. Home and You exist for now.
struct RootTabView: View {
    @Bindable var coordinator: AppCoordinator
    @State private var backdropFrame: CGRect?

    var body: some View {
        Group {
            switch coordinator.selectedTab {
            case .home:
                if let home = coordinator.home { HomeView(viewModel: home, tour: coordinator.tour) }
            case .you:
                if let you = coordinator.you { YouView(viewModel: you) }
            default:
                TabPlaceholder(name: coordinator.selectedTab.rawValue)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            UVVATabBar(active: $coordinator.selectedTab)
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
        .environment(\.backdropFrame, [.home, .you].contains(coordinator.selectedTab) ? backdropFrame : nil)
        .overlayPreferenceValue(SpotlightAnchors.self) { anchors in
            if let tour = coordinator.tour {
                GeometryReader { proxy in
                    GuidedTourView(viewModel: tour, frames: anchors.mapValues { proxy[$0] })
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.35), value: coordinator.tour == nil)
    }
}

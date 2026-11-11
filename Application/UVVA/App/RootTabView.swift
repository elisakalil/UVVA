import Cellar
import CoreUI
import DesignSystem
import Friends
import Home
import Learn
import SwiftUI
import You

struct RootTabView: View {
    @Bindable var coordinator: AppCoordinator
    @State private var backdropFrame: CGRect?
    /// The tab bar stays behind the keyboard instead of riding on it.
    @State private var isKeyboardUp = false

    var body: some View {
        Group {
            switch coordinator.selectedTab {
            case .home:
                if let home = coordinator.home {
                    HomeView(viewModel: home, tour: coordinator.tour, newNote: newNote(from: .home))
                }
            case .learn:
                if let learn = coordinator.learn { LearnView(viewModel: learn) }
            case .cellar:
                if let cellar = coordinator.cellarTab {
                    CellarView(viewModel: cellar, newNote: newNote(from: .cellar))
                }
            case .friends:
                if let friends = coordinator.friends { FriendsView(viewModel: friends) }
            case .you:
                if let you = coordinator.you { YouView(viewModel: you) }
            }
        }
        // A cross-fade when a tab is opened from code (the Home's map card, HOME-R17); taps on the bar stay instant.
        .transition(.opacity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isKeyboardUp {
                UVVATabBar(active: $coordinator.selectedTab)
                    .padding(.bottom, 5)
                    .frame(maxWidth: .infinity)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardUp = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardUp = false
        }
        
        .background {
            Color.clear
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { backdropFrame = $0 }
                .ignoresSafeArea()
        }
        .environment(\.backdropFrame, [.home, .learn, .cellar, .friends, .you].contains(coordinator.selectedTab) ? backdropFrame : nil)
        .overlayPreferenceValue(SpotlightAnchors.self) { anchors in
            if let tour = coordinator.tour {
                GeometryReader { proxy in
                    GuidedTourView(viewModel: tour, frames: anchors.mapValues { proxy[$0] })
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .lessonCover(coordinator.learn, onPresented: coordinator.lessonDidPresent)
        .certificateCover(coordinator.learn)
        .animation(.easeOut(duration: 0.35), value: coordinator.tour == nil)
    }

    private func newNote(from origin: AppTab) -> Binding<NewNoteViewModel?> {
        Binding {
            guard let note = coordinator.newNote, note.origin == origin else { return nil }
            return note.model
        } set: { note in
            if note == nil { coordinator.closeNewNote(from: origin) }
        }
    }
}

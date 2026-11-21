import Cellar
import CoreUI
import DesignSystem
import Friends
import Home
import Learn
import Onboarding
import SwiftUI
import You

struct RootTabView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var coordinator: AppCoordinator
    @State private var backdropFrame: CGRect?
    /// The tab bar stays behind the keyboard instead of riding on it.
    @State private var isKeyboardUp = false
    /// A tab that puts its own bar at the bottom (Friends while choosing who comes).
    @State private var isTabBarHidden = false
    /// HOME-R04: the notifications, opened from the bell in You.
    @State private var showsNotifications = false

    var body: some View {
        ZStack {
            ForEach(AppTab.allCases) { tab in
                if tab == coordinator.selectedTab {
                    tabContent(tab)
                        .transition(.opacity)
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: coordinator.selectedTab)
        .onPreferenceChange(TabBarHiddenKey.self) { isTabBarHidden = $0 }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isKeyboardUp && !isTabBarHidden {
                withUnreadNotifications { unread in
                    UVVATabBar(active: $coordinator.selectedTab, marked: unread ? [.you] : [])
                }
                    .padding(.bottom, 5)
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: isTabBarHidden)
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
        .fullScreenCover(item: Binding(get: { coordinator.addFriends },
                                       set: { if $0 == nil { coordinator.closeAddFriends() } })) { module in
            AddFriendsView(module: module)
        }
        .fullScreenCover(isPresented: $showsNotifications) {
            if let home = coordinator.home {
                NotificationsScreen(viewModel: home) { showsNotifications = false }
            }
        }
        // What friends sent is read again on the way to You, so its bell is up to date.
        .onChange(of: coordinator.selectedTab) { _, tab in
            guard tab == .you, let home = coordinator.home else { return }
            Task { await home.refreshNotifications() }
        }
        .lessonCover(coordinator.learn, onPresented: coordinator.lessonDidPresent)
        .certificateCover(coordinator.learn)
        .animation(.easeOut(duration: 0.35), value: coordinator.tour == nil)
    }

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
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
            if let friends = coordinator.friends { FriendsView(viewModel: friends, newNote: newNote(from: .friends)) }
        case .you:
            if let you = coordinator.you {
                withUnreadNotifications { unread in
                    YouView(viewModel: you, hasUnreadNotifications: unread,
                            onOpenNotifications: coordinator.home == nil ? nil : { showsNotifications = true })
                }
            }
        }
    }

    /// The Home gathers the notifications (HOME-R04); the You tab and its bell show whether one is unread.
    @ViewBuilder
    private func withUnreadNotifications<Content: View>(
        @ViewBuilder _ content: @escaping (Bool) -> Content) -> some View {
        if let home = coordinator.home {
            UnreadNotificationsObserver(home: home, content: content)
        } else {
            content(false)
        }
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

/// Watches the Home's notifications, so only what shows the unread dot redraws when they change.
private struct UnreadNotificationsObserver<Content: View>: View {
    @ObservedObject var home: HomeViewModel
    @ViewBuilder var content: (Bool) -> Content

    var body: some View { content(home.uiModel.hasUnreadNotifications) }
}

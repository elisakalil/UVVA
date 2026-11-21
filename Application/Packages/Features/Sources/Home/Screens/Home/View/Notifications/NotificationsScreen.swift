import Core
import SwiftUI

public extension HomeUIModel {
    /// HOME-R04: a notification not opened yet, for the dot on the You tab and its bell.
    var hasUnreadNotifications: Bool { notifications.contains { !$0.isRead } }
}

/// HOME-R04: the list of notifications, opened from the bell in You. The Home still gathers them (what friends sent,
/// the map, the lessons); this is the list over the screen, read again as it opens. A tapped line closes it and
/// goes where it points (HOME-R04b).
public struct NotificationsScreen<ViewModel: HomeViewModelProtocol>: View {
    @ObservedObject private var viewModel: ViewModel
    private let onClose: () -> Void

    public init(viewModel: ViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    public var body: some View {
        HomeNotificationsView(
            resources: viewModel.uiModel.resources,
            notifications: viewModel.uiModel.notifications,
            onOpen: { notification in
                onClose()
                Task { await viewModel.openNotification(notification) }
            },
            onClose: onClose)
            .task { await viewModel.refreshNotifications() }
    }
}

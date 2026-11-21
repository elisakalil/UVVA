import Core
import DesignSystem
import SwiftUI

/// HOME-R04: the list the bell opens, over the Home's photo. Opening it marks nothing as read; tapping a line does,
/// and goes where it points (HOME-R04b).
struct HomeNotificationsView: View {
    var resources = HomeResourcesUIModel()
    var notifications: [AppNotification]
    var onOpen: (AppNotification) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if notifications.isEmpty {
                empty
            } else {
                list
            }
        }
        .foregroundStyle(UVVAColor.creamFill)
        .presentationBackground { Self.backdrop }
    }

    private var header: some View {
        HStack {
            Text(resources.notificationsTitle.uppercased())
                .font(UVVAFont.sans(9))
                .tracking(2.7)
                .foregroundStyle(UVVAColor.creamFill.opacity(0.7))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 16)
            Button(action: onClose) {
                Text(resources.notificationsClose.uppercased())
                    .font(UVVAFont.sans(11))
                    .tracking(2)
                    .foregroundStyle(UVVAColor.creamFill.opacity(0.7))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .padding(.horizontal, Self.inset)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                    row(notification)
                        .overlay(alignment: .top) {
                            if index > 0 {
                                Rectangle().fill(UVVAColor.creamFill.opacity(0.12)).frame(height: 1)
                            }
                        }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, Self.inset)
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
    }

    private func row(_ notification: AppNotification) -> some View {
        let text = resources.notificationText(notification.kind)
        let when = resources.notificationWhen(notification.date, now: .now)
        return Button { onOpen(notification) } label: {
            HStack(alignment: .top, spacing: 14) {
                Circle()
                    .fill(notification.isRead ? Color.clear : UVVAColor.creamFill.opacity(0.9))
                    .overlay { Circle().strokeBorder(UVVAColor.creamFill.opacity(0.4), lineWidth: 0.5) }
                    .frame(width: 6, height: 6)
                    .padding(.top, 6)
                VStack(alignment: .leading, spacing: 7) {
                    Text(text)
                        .font(UVVAFont.sans(13.5))
                        .lineSpacing(2)
                        .foregroundStyle(UVVAColor.creamFill.opacity(0.92))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(when.uppercased())
                        .font(UVVAFont.sans(9))
                        .tracking(1.8)
                        .foregroundStyle(UVVAColor.creamFill.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(notification.isRead ? "\(text), \(when)" : "\(resources.notificationUnreadLabel), \(text), \(when)")
        .accessibilityAddTraits(.isButton)
    }

    private var empty: some View {
        Text(resources.notificationsEmpty)
            .font(UVVAFont.sans(13.5))
            .lineSpacing(2)
            .multilineTextAlignment(.center)
            .foregroundStyle(UVVAColor.creamFill.opacity(0.7))
            .frame(maxWidth: 280)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Self.inset)
            .padding(.bottom, 60)
    }

    static let inset: CGFloat = 26

    /// The Home seen through a dark blur, tinted with the moss of the page.
    static var backdrop: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
            Color(red: 20 / 255, green: 26 / 255, blue: 16 / 255).opacity(0.52)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    Color.clear.fullScreenCover(isPresented: .constant(true)) {
        HomeNotificationsView(notifications: [
            .init(id: "1", kind: .friendRequest(userID: "r", name: "Rita"), date: .now, isRead: false),
            .init(id: "2", kind: .wineReceived(id: "w", from: "Marina", wine: "Mencía, Bierzo"),
                  date: .now.addingTimeInterval(-7200), isRead: false),
            .init(id: "3", kind: .mapMoved(axis: .tannin, delta: 0.1), date: .now.addingTimeInterval(-90000), isRead: true),
            .init(id: "4", kind: .lessonWaiting(courseID: "c", course: "Douro", lesson: 3),
                  date: .now.addingTimeInterval(-100000), isRead: true),
            .init(id: "5", kind: .newFriend(friendID: "t", name: "Tomás", compatibility: 82),
                  date: .now.addingTimeInterval(-3 * 86400), isRead: true)
        ], onOpen: { _ in }, onClose: {})
    }
    .background { PageBackground() }
}

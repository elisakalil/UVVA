import DesignSystem
import SwiftUI

/// YOU-R01, with the bell of the notifications at the edge (HOME-R04): a dot when one is not opened yet.
struct YouHeader: View {
    var model: YouHeaderUIModel
    var hasUnreadNotifications = false
    /// Nil: no bell (previews, or a You with no notifications to show).
    var onOpenNotifications: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            Avatar(photo: model.photo)
            VStack(alignment: .leading, spacing: 6) {
                Text(model.name)
                    .font(UVVAFont.sans(24, .ultraLight))
                    .tracking(-0.36)
                Text(model.signature)
                    .font(UVVAFont.sans(9.5))
                    .tracking(1.9)
                    .opacity(0.8)
            }
            Spacer(minLength: 0)
            if let onOpenNotifications { bell(onOpenNotifications) }
        }
    }

    private func bell(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            BellIcon()
                .stroke(UVVAColor.creamFill, style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 22)
                .frame(width: 44, height: 44)
                .overlay(alignment: .topTrailing) {
                    if hasUnreadNotifications {
                        Circle().fill(UVVAColor.creamFill).frame(width: 5, height: 5)
                            .padding(.top, 9).padding(.trailing, 10)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                // A plain button only takes taps on what it draws: the bell's thin line alone answered.
                .contentShape(Rectangle())
                .animation(.easeOut(duration: 0.2), value: hasUnreadNotifications)
        }
        .buttonStyle(.plain)
        // Its stroke level with the edge of the page.
        .padding(.trailing, -10)
        .accessibilityLabel(hasUnreadNotifications ? String(localized: "Notifications, unread", bundle: .module)
                                                   : String(localized: "Notifications", bundle: .module))
    }
}

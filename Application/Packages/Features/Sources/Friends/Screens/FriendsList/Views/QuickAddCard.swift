import DesignSystem
import SwiftUI

/// A contact on UVVA (FRI-R07), as a card in the Quick add strip: the avatar with `+`, and the name.
/// Tapping it sends the request (FRI-R08) and the `+` turns to `✓`; tapping again takes it back (D11).
/// "Not now" (FRI-R09) stays in the long press and among the accessibility actions.
struct QuickAddCard: View {
    var resources: FriendsResourcesUIModel
    var row: QuickAddRowUIModel
    var onAdd: () -> Void
    var onCancel: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button(action: row.isRequested ? onCancel : onAdd) {
            VStack(spacing: 8) {
                FriendsAvatar(size: 46)
                    .overlay(alignment: .topTrailing) { badge.offset(x: 4, y: -2) }
                Text(row.name)
                    .font(UVVAFont.sans(11.5))
                    .opacity(0.88)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 74)
            .opacity(row.isRequested ? 0.6 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.25), value: row.isRequested)
        .contextMenu {
            if !row.isRequested {
                Button(resources.dismissText, systemImage: resources.dismissIcon, action: onDismiss)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.name)
        .accessibilityValue(row.isRequested ? resources.requestedText : row.signature)
        .accessibilityHint(row.isRequested ? resources.cancelRequestHint : resources.addText)
        .accessibilityAction(named: resources.dismissText) { if !row.isRequested { onDismiss() } }
    }

    private var badge: some View {
        Text(verbatim: row.isRequested ? "✓" : "+")
            .font(UVVAFont.sans(row.isRequested ? 8 : 12, .ultraLight))
            .opacity(0.85)
            .frame(width: 15, height: 15)
            .background(UVVAColor.moss, in: Circle())
            .overlay(Circle().strokeBorder(UVVAColor.creamFill.opacity(0.45), lineWidth: 0.5))
            .contentTransition(.opacity)
    }
}

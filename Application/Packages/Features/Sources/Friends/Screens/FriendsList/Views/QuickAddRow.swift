import DesignSystem
import SwiftUI

/// A contact on UVVA (FRI-R07): Add, then Requested (FRI-R08), which takes the request back (D11); `×` (FRI-R09).
struct QuickAddRow: View {
    var resources: FriendsResourcesUIModel
    var row: QuickAddRowUIModel
    var onAdd: () -> Void
    var onCancel: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            FriendsPersonLabel(name: row.name, signature: row.signature)
            FriendsPillButton(title: row.isRequested ? resources.requestedText : resources.addText,
                              isSolid: row.isRequested, action: row.isRequested ? onCancel : onAdd)
                .accessibilityHint(row.isRequested ? resources.cancelRequestHint : "")
            if !row.isRequested {
                Button(action: onDismiss) {
                    Image(systemName: resources.dismissIcon)
                        .font(.system(size: 12, weight: .light))
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(0.7)
                .accessibilityLabel(resources.dismissText)
            }
        }
        .padding(.vertical, 12)
    }
}

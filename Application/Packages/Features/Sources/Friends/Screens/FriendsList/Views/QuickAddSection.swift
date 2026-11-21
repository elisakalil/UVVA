import DesignSystem
import SwiftUI

/// Quick add (FRI-R07, R07a): the suggestions in a strip across the page, or what is needed to get them.
struct QuickAddSection: View {
    var resources: FriendsResourcesUIModel
    var state: QuickAddState
    var onAdd: (String) -> Void
    var onCancel: (String) -> Void
    var onDismiss: (String) -> Void
    var onAskAccess: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FriendsSectionLabel(text: resources.quickAddText)
            switch state {
            case .askAccess:
                message(resources.askAccessText, action: resources.allowContactsText, perform: onAskAccess)
            case .openSettings:
                message(resources.deniedAccessText, action: resources.openSettingsText, perform: onOpenSettings)
            case .noSuggestions:
                // The tab shows `FriendsInviteCard` instead of this section (FRI-R07b).
                EmptyView()
            case let .suggestions(rows):
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(rows) { row in
                            QuickAddCard(resources: resources, row: row,
                                         onAdd: { onAdd(row.id) }, onCancel: { onCancel(row.id) },
                                         onDismiss: { onDismiss(row.id) })
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -30)
                .padding(.top, 10)
            }
        }
    }

    private func message(_ text: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text).font(UVVAFont.sans(12.5)).lineSpacing(3).opacity(0.76)
                .fixedSize(horizontal: false, vertical: true)
            FriendsPillButton(title: action, isSolid: false, action: perform)
        }
        .padding(.top, 12)
    }
}

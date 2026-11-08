import DesignSystem
import SwiftUI

/// Quick add (FRI-R07, R07a): the suggestions, or what is needed to get them.
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
            SectionLabel(text: resources.quickAddText)
                .padding(.bottom, 6)
            switch state {
            case .askAccess:
                message(resources.askAccessText, action: resources.allowContactsText, perform: onAskAccess)
            case .openSettings:
                message(resources.deniedAccessText, action: resources.openSettingsText, perform: onOpenSettings)
            case .noSuggestions:
                Text(resources.noSuggestionsText)
                    .font(UVVAFont.sans(12.5)).lineSpacing(3).opacity(0.75)
                    .padding(.vertical, 12)
            case let .suggestions(rows):
                ForEach(rows) { row in
                    QuickAddRow(resources: resources, row: row,
                                onAdd: { onAdd(row.id) }, onCancel: { onCancel(row.id) }, onDismiss: { onDismiss(row.id) })
                    if row.id != rows.last?.id { FriendsRule() }
                }
            }
        }
    }

    private func message(_ text: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text).font(UVVAFont.sans(12.5)).lineSpacing(3).opacity(0.75)
                .fixedSize(horizontal: false, vertical: true)
            FriendsPillButton(title: action, isSolid: false, action: perform)
        }
        .padding(.vertical, 12)
    }
}

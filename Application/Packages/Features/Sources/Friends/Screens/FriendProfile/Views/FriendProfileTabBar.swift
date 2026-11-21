import DesignSystem
import SwiftUI

/// Palate / Compatibility / Table (FRI-R10): the chosen one brighter and underlined, over a hairline across the page.
struct FriendProfileTabBar: View {
    var resources: FriendProfileResourcesUIModel
    var selected: FriendProfileTab
    var onSelect: (FriendProfileTab) -> Void

    var body: some View {
        // The chosen tab's line lies over the hairline.
        ZStack(alignment: .bottom) {
            FriendsHairline()
            HStack(spacing: 0) {
                ForEach(FriendProfileTab.allCases, id: \.self) { tab in
                    let isSelected = tab == selected
                    Button { withAnimation(.easeOut(duration: 0.2)) { onSelect(tab) } } label: {
                        Text(resources.tab(tab).uppercased())
                            .font(UVVAFont.sans(isSelected ? 11.5 : 11))
                            .tracking(1.1)
                            .lineLimit(1)
                            .opacity(isSelected ? 1 : 0.45)
                            .padding(.top, 14)
                            .padding(.bottom, 13)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(UVVAColor.creamFill.opacity(isSelected ? 0.7 : 0)).frame(height: 1)
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 26)
        }
    }
}

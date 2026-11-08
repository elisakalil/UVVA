import DesignSystem
import SwiftUI

/// Palate / Compatibility / Table, over a hairline (FRI-R10), like the tabs of You.
struct FriendProfileTabBar: View {
    var resources: FriendProfileResourcesUIModel
    var selected: FriendProfileTab
    var onSelect: (FriendProfileTab) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(FriendProfileTab.allCases, id: \.self) { tab in
                    Button { withAnimation(.easeOut(duration: 0.2)) { onSelect(tab) } } label: {
                        Text(resources.tab(tab).uppercased())
                            .font(UVVAFont.sans(11))
                            .tracking(1.1)
                            .opacity(tab == selected ? 1 : 0.45)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(tab == selected ? .isSelected : [])
                }
            }
            Rectangle().fill(Color(hex: 0xE2D5BA).opacity(0.7)).frame(height: 1)
        }
    }
}

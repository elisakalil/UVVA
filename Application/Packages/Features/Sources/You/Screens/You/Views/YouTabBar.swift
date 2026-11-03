import DesignSystem
import SwiftUI

/// Progress / Map / Settings, over a hairline (YOU-R02).
struct YouTabBar: View {
    @Binding var selected: YouTab

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(YouTab.allCases, id: \.self) { tab in
                    Button { withAnimation(.easeOut(duration: 0.2)) { selected = tab } } label: {
                        Text(tab.title.uppercased())
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

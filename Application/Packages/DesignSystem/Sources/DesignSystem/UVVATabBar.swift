import SwiftUI

/// The floating glass tab bar from the design system (TabBar): text only, no icons.
/// The active tab is a brighter glass capsule with cream text in 400; the others are cream in 300.
public struct UVVATabBar: View {
    @Binding var active: AppTab

    public init(active: Binding<AppTab>) { _active = active }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isActive = tab == active
                Button { active = tab } label: {
                    Text(tab.rawValue)
                        .font(UVVAFont.sans(11.5, isActive ? .regular : .light))
                        .tracking(0.66)
                        .lineLimit(1)
                        .foregroundStyle(isActive ? UVVAColor.cream : UVVAColor.cream.opacity(0.72))
                        .padding(.horizontal, 4)
                        .frame(minWidth: 61, minHeight: 30)
                        .background {
                            if isActive {
                                Capsule()
                                    .fill(LinearGradient(colors: [.white.opacity(0.24), .white.opacity(0.1)],
                                                         startPoint: .top, endPoint: .bottom))
                                    .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
                                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
                .spotlightAnchor(tab.spotlightID)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 5)
        .background { FrostedGlass(radius: 21, dense: true) }
    }
}

#Preview {
    @Previewable @State var tab = AppTab.cellar
    ZStack {
        UVVAColor.moss.ignoresSafeArea()
        UVVATabBar(active: $tab)
    }
}
